// ----------------------------------------------------------------------------------
// Copyright 2023 Intel Corp.
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//	   http://www.apache.org/licenses/LICENSE-2.0
//
//	Unless required by applicable law or agreed to in writing, software
//	distributed under the License is distributed on an "AS IS" BASIS,
//	WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
//	See the License for the specific language governing permissions and
//	limitations under the License.
//
// ----------------------------------------------------------------------------------

package main

import (
	"bufio"
	"context"
	"encoding/json"
	"flag"
	"fmt"
	"io"
	"log"
	"os"
	"os/exec"
	"path/filepath"
	"strconv"
	"strings"
	"sync"
	"time"

	"github.com/intel-retail/automated-self-checkout/configs/opencv-ovms/cmd_client/parser"
	"github.com/intel-retail/automated-self-checkout/configs/opencv-ovms/cmd_client/portfinder"
	"github.com/intel-retail/automated-self-checkout/configs/opencv-ovms/cmd_client/server"

	grpc_client "github.com/intel-retail/automated-self-checkout/configs/opencv-ovms/cmd_client/grpc-client"
	"google.golang.org/grpc"
	"gopkg.in/yaml.v3"
)

type StartPolicy int

const (
	Ignore StartPolicy = iota
	Exit
	RemoveRestart
)

func (policy StartPolicy) String() string {
	return [...]string{
		"ignore",
		"exit",
		"remove-and-restart",
	}[policy]
}

const (
	ENV_KEY_VALUE_DELIMITER = "="

	profileLaunchedContainerNameSuffix = "_ovms_pl"
	defaultGrpcPortFrom                = 9001
	defaultTargetDevice                = "CPU"

	scriptDir                = "./scripts"
	envFileDir               = "./envs"
	pipelineProfileEnv       = "PIPELINE_PROFILE"
	resourceDir              = "res"
	pipelineConfigFileName   = "configuration.yaml"
	commandLineArgsDelimiter = " "
	streamDensityScript      = "/app/stream_density.sh"
	streamDensityResultDir   = "/tmp/results"

	ovmsConfigJsonDir        = "./configs/opencv-ovms/models/2022"
	ovmsTemplateConfigJson   = "config_template.json"
	ovmsModelReadyMaxRetries = 100

	defaultOvmsServerStartWaitTime = time.Duration(10 * time.Second)
	dockerVolumeFlag               = "-v"
)

const (
	OVMS_SERVER_DOCKER_IMG_ENV      = "OVMS_SERVER_IMAGE_TAG"
	OVMS_SERVER_START_UP_MSG_ENV    = "SERVER_START_UP_MSG"
	SERVER_CONTAINER_NAME_ENV       = "SERVER_CONTAINER_NAME"
	OVMS_MODEL_CONFIG_JSON_PATH_ENV = "OVMS_MODEL_CONFIG_JSON"
	OVMS_INIT_WAIT_TIME_ENV         = "SERVER_INIT_WAIT_TIME"
	CID_COUNT_ENV                   = "cid_count"
	RESULT_DIR_ENV                  = "RESULT_DIR"
	DOT_ENV_FILE_ENV                = "DOT_ENV_FILE"
	GRPC_PORT_ENV                   = "GRPC_PORT"
	TARGET_DEVICE_ENV               = "DEVICE"
)

type OvmsServerInfo struct {
	ServerDockerScript       string
	ServerDockerImage        string
	ServerContainerName      string
	ServerConfig             string
	StartupMessage           string
	InitWaitTime             string
	EnvironmentVariableFiles []string
	StartUpPolicy            string
}

const (
	// constants define the environment variable keys
	DOCKER_LAUNCHER_SCRIPT_ENV = "DOCKER_LAUNCHER_SCRIPT"
	DOCKER_VOLUMES_ENV         = "VOLUMES"
	DOCKER_IMAGE_ENV           = "DOCKER_IMAGE"
	DOCKER_CONTAINER_NAME_ENV  = "CONTAINER_NAME"
	DOCKER_CMD_ENV             = "DOCKER_CMD"
)

type DockerLauncherInfo struct {
	LauncherScript string   `yaml:"Script" json:"Script"`
	DockerImage    string   `yaml:"DockerImage" json:"DockerImage"`
	ContainerName  string   `yaml:"ContainerName" json:"ContainerName"`
	DockerVolumes  []string `yaml:"Volumes" json:"Volumes"`
}

type OvmsClientInfo struct {
	DockerLauncher           DockerLauncherInfo
	PipelineScript           string
	PipelineInputArgs        string
	PipelineStreamDensityRun string
	EnvironmentVariableFiles []string
}

type OvmsClientConfig struct {
	OvmsSingleContainer bool
	OvmsServer          OvmsServerInfo
	OvmsClient          OvmsClientInfo
}

type Flags struct {
	FlagSet   *flag.FlagSet
	configDir string
}

func main() {
	flagSet := flag.NewFlagSet("", flag.ExitOnError)
	flags := &Flags{
		FlagSet: flagSet,
	}
	flagSet.StringVar(&flags.configDir, "configDir", filepath.Join(".", resourceDir), "")
	flagSet.StringVar(&flags.configDir, "cd", filepath.Join(".", resourceDir), "")
	err := flags.FlagSet.Parse(os.Args[1:])
	if err != nil {
		flagSet.Usage()
		log.Fatalln(err)
	}

	// the config yaml file is in res/ folder of the "pipeline profile" directory
	contents, err := flags.readPipelineConfig()
	if err != nil {
		log.Fatalf("failed to read configuration yaml file: %v", err)
	}

	data := make(map[string]any)
	err = yaml.Unmarshal(contents, &data)
	if err != nil {
		log.Fatalf("failed to unmarshal configuration file configuration.yaml: %v", err)
	}

	log.Println("data: ", data)

	// convert to struct
	jsonBytes, err := json.Marshal(data)
	if err != nil {
		log.Fatalf("could not marshal map to JSON: %v", err)
	}

	var ovmsClientConf *OvmsClientConfig
	if err := json.Unmarshal(jsonBytes, &ovmsClientConf); err != nil {
		log.Fatalf("could not unmarshal JSON data to %T: %v", *ovmsClientConf, err)
	}

	log.Println("successfully converted to OvmsClientConfig struct", *ovmsClientConf)

	// set the env values for CID_COUNT_ENV and GRPC_PORT_ENV based on the number of profile Docker container instances
	ovmsClientConf.setEnvContainerCountAndGrpcPort()

	// if OvmsSingleContainer mode is true, then we don't launcher another ovms server
	// as the client itself has it like C-Api case
	if ovmsClientConf.OvmsSingleContainer {
		log.Println("running in single container mode, no distributed client-server")
		ovmsClientConf.generateConfigJsonForCApi()
	} else {
		// launcher ovms server
		ovmsClientConf.startOvmsServer()
	}

	// initialize the docker-launcher envs:
	ovmsClientConf.initDockerLauncherEnvs()

	//launch the pipeline script from the config
	if err := ovmsClientConf.launchPipelineScript(); err != nil {
		log.Fatalf("found error while launching pipeline script: %v", err)
	}

}

func (ovmsClientConf *OvmsClientConfig) setEnvContainerCountAndGrpcPort() {
	// utilize docker ps to find out how many has been launched by profile-launcher and thus
	// decide the cid_count value; it is equivalent to the command line: docker ps -aq -f name=<profileLaunchedContainerNameSuffix> | wc -w
	dockerPsCmd := exec.Command("docker", []string{
		"ps", "-aq", "-f name=" + profileLaunchedContainerNameSuffix}...)
	wcCmd := exec.Command("wc", "-w")

	// using pipe to connect the output from the 1st command to input of the 2nd command to figure out cid_count value
	r, w := io.Pipe()
	dockerPsCmd.Stdout = w
	wcCmd.Stdin = r

	res, err := wcCmd.StdoutPipe()
	if err != nil {
		log.Fatalf("failed to get stdout pipe from wc command:%v", err)
	}
	if err := dockerPsCmd.Start(); err != nil {
		log.Fatalf("failed to docker ps filter name `%s` command for containers launched by profile-launcher: %v", profileLaunchedContainerNameSuffix, err)
	}
	if err := wcCmd.Start(); err != nil {
		log.Fatalf("failed to run wc command to get the docker container counts launched by profile-launcher: %v", err)
	}
	if err := dockerPsCmd.Wait(); err != nil {
		log.Fatalf("docker ps command wait error: %v", err)
	}
	w.Close()

	wcReader := bufio.NewReader(res)
	resBytes, _ := wcReader.ReadString('\n')

	if err := wcCmd.Wait(); err != nil {
		log.Fatalf("wc command wait error: %v", err)
	}

	output := strings.TrimSuffix(string(resBytes), fmt.Sprintln())

	log.Println("output:", output)

	containerCnt := "0"
	if len(output) > 0 {
		containerCnt = output
		// verify the output is an integer
		_, err := strconv.Atoi(containerCnt)
		if err != nil {
			log.Println("failed to parse the output for container count: ", err)
			// assuming the 0 value in this case
			containerCnt = "0"
		}
	} else {
		log.Println("output is empty, containerCnt defaults to 0")
	}

	os.Setenv(CID_COUNT_ENV, containerCnt)

	portFinder := portfinder.PortFinder{
		IpAddress: "localhost",
	}

	grpcPortNum := portFinder.GetFreePortNumber(defaultGrpcPortFrom)
	os.Setenv(GRPC_PORT_ENV, fmt.Sprintf("%d", grpcPortNum))

	log.Println("cid_count=", os.Getenv(CID_COUNT_ENV))
	log.Println("GRPC_PORT=", os.Getenv(GRPC_PORT_ENV))
}

func (ovmsClientConf *OvmsClientConfig) generateConfigJsonForCApi() {
	log.Println("generate and update config json file for C-API case...")

	deviceUpdater := server.NewDeviceUpdater(ovmsConfigJsonDir, ovmsTemplateConfigJson)
	targetDevice := defaultTargetDevice
	if len(os.Getenv(TARGET_DEVICE_ENV)) > 0 {
		// only set the value from env if env is not empty; otherwise defaults to the default value in defaultTargetDevice
		// devices supported CPU, GPU, GPU.x, AUTO, MULTI:GPU,CPU
		targetDevice = os.Getenv(TARGET_DEVICE_ENV)
	}

	log.Println("Updating config with DEVICE environment variable:", targetDevice)

	newUpdateConfigJson := "config_ovms-server_" + ovmsClientConf.OvmsClient.DockerLauncher.ContainerName + os.Getenv(CID_COUNT_ENV) + ".json"

	if err := deviceUpdater.UpdateDeviceAndCreateJson(targetDevice, filepath.Join(ovmsConfigJsonDir, newUpdateConfigJson)); err != nil {
		log.Printf("Error: failed to update device and produce a new ovms server config json: %v", err)
		os.Exit(1)
	}

	configJsonContainer := filepath.Join("/models", newUpdateConfigJson)
	log.Println("configJsonContainer:", configJsonContainer)
	os.Setenv(OVMS_MODEL_CONFIG_JSON_PATH_ENV, configJsonContainer)
}

func (ovmsClientConf *OvmsClientConfig) startOvmsServer() {
	if len(ovmsClientConf.OvmsServer.ServerDockerScript) == 0 {
		log.Println("Error founding any server launch script from OvmsServer.ServerDockerScript, please check configuration.yaml file")
		os.Exit(1)
	}

	log.Println("OVMS server config to launcher: ", ovmsClientConf.OvmsServer)
	os.Setenv(OVMS_SERVER_START_UP_MSG_ENV, ovmsClientConf.OvmsServer.StartupMessage)
	os.Setenv(SERVER_CONTAINER_NAME_ENV, ovmsClientConf.OvmsServer.ServerContainerName)
	os.Setenv(OVMS_SERVER_DOCKER_IMG_ENV, ovmsClientConf.OvmsServer.ServerDockerImage)

	// update device in the template config json:
	deviceUpdater := server.NewDeviceUpdater(ovmsConfigJsonDir, ovmsTemplateConfigJson)
	configFileWithoutExtension := strings.TrimSuffix(filepath.Base(ovmsClientConf.OvmsServer.ServerConfig), ".json")
	newUpdateConfigJson := configFileWithoutExtension + "_" + ovmsClientConf.OvmsServer.ServerContainerName + os.Getenv(CID_COUNT_ENV) + ".json"
	targetDevice := defaultTargetDevice
	if len(os.Getenv(TARGET_DEVICE_ENV)) > 0 {
		// only set the value from env if env is not empty; otherwise defaults to the default value in defaultTargetDevice
		// devices supported CPU, GPU, GPU.x, AUTO, MULTI:GPU,CPU
		targetDevice = os.Getenv(TARGET_DEVICE_ENV)
	}

	log.Println("Updating config with DEVICE environment variable:", targetDevice)

	if err := deviceUpdater.UpdateDeviceAndCreateJson(targetDevice, filepath.Join(ovmsConfigJsonDir, newUpdateConfigJson)); err != nil {
		log.Printf("Error: failed to update device and produce a new ovms server config json: %v", err)
		os.Exit(1)
	}

	configJsonContainer := filepath.Join(filepath.Dir(ovmsClientConf.OvmsServer.ServerConfig), newUpdateConfigJson)
	log.Println("configJsonContainer:", configJsonContainer)
	os.Setenv(OVMS_MODEL_CONFIG_JSON_PATH_ENV, configJsonContainer)

	serverScript := filepath.Join(scriptDir, ovmsClientConf.OvmsServer.ServerDockerScript)
	ovmsSrvLaunch, err := exec.LookPath(serverScript)
	if err != nil {
		log.Printf("Error: failed to get ovms server launch script path: %v", err)
		os.Exit(1)
	}

	log.Println("launch ovms server script:", ovmsSrvLaunch)
	startupPolicy := Ignore.String()
	if len(ovmsClientConf.OvmsServer.StartUpPolicy) > 0 {
		startupPolicy = ovmsClientConf.OvmsServer.StartUpPolicy
	}
	switch startupPolicy {
	case Ignore.String(), Exit.String(), RemoveRestart.String():
		log.Println("chose ovms server startup policy:", startupPolicy)
	default:
		startupPolicy = Ignore.String()
		log.Println("ovms server startup policy defaults to", Ignore.String())
	}

	cmd := exec.Command(ovmsSrvLaunch)
	cmd.Env = os.Environ()
	origEnvs := make([]string, len(cmd.Env))
	copy(origEnvs, cmd.Env)
	// apply all envs from env files if any
	envList := ovmsClientConf.OvmsServer.readServerEnvs(envFileDir)
	cmd.Env = append(cmd.Env, envList...)
	// override envs from the origEnvs
	cmd.Env = append(cmd.Env, origEnvs...)

	output, err := cmd.CombinedOutput()
	if err != nil {
		log.Printf("failed to run the ovms server launch : %v", err)
		log.Printf("output: %v", string(output))
		// based on the startup policy when there is error on launching ovms server,
		// it will deal it differently:
		switch startupPolicy {
		case Exit.String():
			os.Exit(1)
		case RemoveRestart.String():
			rmvContainerName := ovmsClientConf.OvmsServer.ServerContainerName + os.Getenv(CID_COUNT_ENV)
			rmvCmd := exec.Command("docker", []string{"rm", "-f", rmvContainerName}...)
			if rmvErr := rmvCmd.Run(); rmvErr != nil {
				log.Printf("failed to remove the existing container with container name %s: %v", rmvContainerName, rmvErr)
			}
			time.Sleep(time.Second)
			ovmsClientConf.startOvmsServer()
		default:
			fallthrough
		case Ignore.String():
			log.Println("startup error is ignored due to ignore startup policy")
			// in this case, we also need to reset the env $GRPC_PORT to the ignored model server's one
			// otherwise, the client will use the wrong port number
			ovmsContainerName := ovmsClientConf.OvmsServer.ServerContainerName + os.Getenv(CID_COUNT_ENV)
			log.Printf("ovmsContainer name: %s", ovmsContainerName)
			ovmsSrvPortNum, err := getServerGrpcPort(ovmsContainerName)
			if err != nil {
				log.Fatalf("failed to get server gRPC port number: %v", err)
			}
			os.Setenv(GRPC_PORT_ENV, ovmsSrvPortNum)
		}
	}

	ovmsSrvWaitTime := defaultOvmsServerStartWaitTime
	if len(ovmsClientConf.OvmsServer.InitWaitTime) > 0 {
		ovmsSrvWaitTime, err = time.ParseDuration(ovmsClientConf.OvmsServer.InitWaitTime)
		if err != nil {
			log.Printf("Error parsing ovmsClientConf.OvmsServer.InitWaitTime %s, using default value %v : %s",
				ovmsClientConf.OvmsServer.InitWaitTime, defaultOvmsServerStartWaitTime, err)
			ovmsSrvWaitTime = defaultOvmsServerStartWaitTime
		}
	}

	log.Println("Let server settle a bit...")
	time.Sleep(ovmsSrvWaitTime)

	// wait for the model ready state status:
	// even though the ovms server is ready but the individual models may not be
	// due to the model config file config.json changes on the fly
	retryCnt := 0
	for {
		if retryCnt >= ovmsModelReadyMaxRetries {
			log.Printf("error: reaches the max retry count %d for checking model ready of ovms server; gave up", ovmsModelReadyMaxRetries)
			return
		}

		retryCnt++
		readyErr := ovmsClientConf.waitForOvmsModelsReady()
		if readyErr == nil {
			// all are error free and thus models are ready
			break
		}

		log.Printf("warning: ovms models from the model server not ready yet: %v", readyErr)
		// sleep a bit and retry it again
		time.Sleep(time.Second)
	}

	log.Println("OVMS server started and ready to serve")
}

func (ovmsClientConf *OvmsClientConfig) waitForOvmsModelsReady() error {
	grpcPort := os.Getenv(GRPC_PORT_ENV)
	ovmsURL := fmt.Sprintf("%s:%s", "localhost", grpcPort)
	conn, err := grpc.Dial(ovmsURL, grpc.WithInsecure())
	if err != nil {
		return fmt.Errorf("couldn't connect to endpoint %s: %v", ovmsURL, err)
	}
	defer conn.Close()

	// retrieve models:
	ovmsModelParser := parser.NewConfigJsonModelParser(ovmsConfigJsonDir, ovmsTemplateConfigJson)
	if err = ovmsModelParser.Parse(); err != nil {
		return fmt.Errorf("couldn't parse OVMS config json: %v", err)
	}

	if len(ovmsModelParser.ModelConfigList) > 0 {
		// Create client from gRPC server connection
		client := grpc_client.NewGRPCInferenceServiceClient(conn)

		var wg sync.WaitGroup
		wg.Add(len(ovmsModelParser.ModelConfigList))
		for _, model := range ovmsModelParser.ModelConfigList {
			go func(model parser.ModelConfigListInfo) {
				defer wg.Done()
				modelName := model.Config.ModelName
				// we use /1 folder under the model so the model version is always 1
				modelVersion := "1"
				modelReadyResponse, err := sendModelReadyRequest(client, modelName, modelVersion)
				if err == nil && modelReadyResponse.Ready {
					log.Printf("Model name %s with version %s is ready", modelName, modelVersion)
					return
				}

				// this model is not in ready state yet
				// we will re-test this specific model for max retry
				retryCnt := 0
				for {
					if retryCnt >= ovmsModelReadyMaxRetries {
						log.Printf("error: reaches the max retry count %d for checking model ready of ovms server; gave up", ovmsModelReadyMaxRetries)
						return
					}

					time.Sleep(time.Second)
					retryCnt++
					// need new client every time since there is some cached issue if re-using the existing client
					client := grpc_client.NewGRPCInferenceServiceClient(conn)
					modelReadyResponse, err := sendModelReadyRequest(client, modelName, modelVersion)
					if err == nil && modelReadyResponse.Ready {
						log.Printf("Model name %s with version %s is ready", modelName, modelVersion)
						break
					}
				}
			}(model)
		}
		wg.Wait()
	}
	return nil
}

func sendModelReadyRequest(client grpc_client.GRPCInferenceServiceClient, modelName string, modelVersion string) (*grpc_client.ModelReadyResponse, error) {
	// Create context for request with 10 second timeout
	// if any request takes longer than that, we consider the system is way too slow and thus unusable
	ctx, cancel := context.WithTimeout(context.Background(), 10*time.Second)
	defer cancel()

	modelReadyRequest := grpc_client.ModelReadyRequest{
		Name:    modelName,
		Version: modelVersion,
	}

	modelReadyResponse, err := client.ModelReady(ctx, &modelReadyRequest)
	if err != nil {
		errMsg := fmt.Errorf("Couldn't get model name %s version %s ready state: %v", modelName, modelVersion, err)
		log.Println(errMsg)
		return nil, errMsg
	}

	return modelReadyResponse, nil
}

func (ovmsClientConf *OvmsClientConfig) initDockerLauncherEnvs() {
	// default script for docker launcher
	launcherScript := "docker-launcher.sh"
	if len(ovmsClientConf.OvmsClient.DockerLauncher.LauncherScript) > 0 {
		launcherScript = ovmsClientConf.OvmsClient.DockerLauncher.LauncherScript
	}

	// process the volumes elements if any
	volumeEnvStr := ""
	if len(ovmsClientConf.OvmsClient.DockerLauncher.DockerVolumes) == 0 {
		log.Println("NO Docker volumes defined")
	}

	for _, volume := range ovmsClientConf.OvmsClient.DockerLauncher.DockerVolumes {
		volumeEnvStr = strings.Join([]string{volumeEnvStr, dockerVolumeFlag, volume}, commandLineArgsDelimiter)
	}

	pipelineRunCmd := ovmsClientConf.OvmsClient.PipelineScript
	streamDensityMode := os.Getenv("STREAM_DENSITY_MODE")
	if streamDensityMode == "1" {
		volumeEnvStr = strings.Join([]string{
			volumeEnvStr,
			dockerVolumeFlag,
			strings.Join([]string{
				"\"$RUN_PATH\"/benchmark-scripts/stream_density.sh",
				streamDensityScript}, ":"),
		}, commandLineArgsDelimiter)

		pipelineRunCmd = strings.Join([]string{
			streamDensityScript,
			ovmsClientConf.OvmsClient.PipelineScript,
		}, commandLineArgsDelimiter)
		os.Setenv(RESULT_DIR_ENV, streamDensityResultDir)
	}

	inputArgs := strings.TrimSpace(ovmsClientConf.OvmsClient.PipelineInputArgs)
	if len(inputArgs) > 0 {
		pipelineRunCmd = strings.Join([]string{
			pipelineRunCmd,
			inputArgs,
		}, commandLineArgsDelimiter)
	}

	os.Setenv(DOCKER_LAUNCHER_SCRIPT_ENV, launcherScript)
	os.Setenv(DOCKER_IMAGE_ENV, ovmsClientConf.OvmsClient.DockerLauncher.DockerImage)
	// append the CONTAINER_NAME env with profileLaunchedContainerNameSuffix so that it is easier to recognize those Docker containers
	// launched by profile-launcher
	os.Setenv(DOCKER_CONTAINER_NAME_ENV, ovmsClientConf.OvmsClient.DockerLauncher.ContainerName+profileLaunchedContainerNameSuffix)
	os.Setenv(DOCKER_VOLUMES_ENV, strings.TrimSpace(volumeEnvStr))
	os.Setenv(DOCKER_CMD_ENV, pipelineRunCmd)

	log.Println(fmt.Sprintf("%s=%s", DOCKER_LAUNCHER_SCRIPT_ENV, os.Getenv(DOCKER_LAUNCHER_SCRIPT_ENV)))
	log.Println(fmt.Sprintf("%s=%s", DOCKER_IMAGE_ENV, os.Getenv(DOCKER_IMAGE_ENV)))
	log.Println(fmt.Sprintf("%s=%s", DOCKER_VOLUMES_ENV, os.Getenv(DOCKER_VOLUMES_ENV)))
	log.Println(fmt.Sprintf("%s=%s", DOCKER_CONTAINER_NAME_ENV, os.Getenv(DOCKER_CONTAINER_NAME_ENV)))
	log.Println(fmt.Sprintf("%s=%s", DOCKER_CMD_ENV, os.Getenv(DOCKER_CMD_ENV)))
}

func (ovmsClientConf *OvmsClientConfig) launchPipelineScript() error {
	launcherScript := filepath.Join(scriptDir, os.Getenv(DOCKER_LAUNCHER_SCRIPT_ENV))
	executable, err := exec.LookPath(launcherScript)
	if err != nil {
		return fmt.Errorf("failed to get pipeline executable path: %v", err)
	}

	log.Println("running executable:", executable)
	cmd := exec.Command(executable)
	cmd.Env = os.Environ()

	// in order to do the environment override from the current existing cmd.Env,
	// we have to save this and then apply the overrides with the existing keys
	origEnvs := make([]string, len(cmd.Env))
	copy(origEnvs, cmd.Env)
	// apply all envs from env files if any
	envList := ovmsClientConf.OvmsClient.readClientEnvs(envFileDir)
	cmd.Env = append(cmd.Env, envList...)
	// override envs from the origEnvs
	cmd.Env = append(cmd.Env, origEnvs...)

	// write envs to a temp file to be used in script
	envWriter := NewTmpEnvFileWriter(cmd.Env)
	if err := envWriter.writeEnvs(); err != nil {
		return fmt.Errorf("failed to write the envs by envWriter: %v", err)
	}
	defer func() {
		err := envWriter.cleanFile()
		if err != nil {
			log.Println("failed to clean tmp env file: ", envWriter.envFile.Name())
		}
	}()
	// make the env file name to the env so that the script can use it
	cmd.Env = append(cmd.Env, strings.Join([]string{DOT_ENV_FILE_ENV, envWriter.envFile.Name()}, envDelimiter))

	envs := cmd.Env
	for _, env := range envs {
		log.Println("environment variable: ", env)
	}
	if len(envs) == 0 {
		log.Println("empty environment variable")
	}

	stdout, err := cmd.StdoutPipe()
	if err != nil {
		return fmt.Errorf("failed to get the output from executable: %v", err)
	}
	stderr, err := cmd.StderrPipe()
	if err != nil {
		return fmt.Errorf("failed to get the error pipe from executable: %v", err)
	}
	if err := cmd.Start(); err != nil {
		return fmt.Errorf("failed to start the pipeline executable: %v", err)
	}

	stdoutBytes, _ := io.ReadAll(stdout)
	log.Println("stdoutBytes: ", string(stdoutBytes))
	stdErrBytes, _ := io.ReadAll(stderr)
	if err := cmd.Wait(); err != nil {
		return fmt.Errorf("found error while executing pipeline scripts- stdErrMsg: %s, Err: %v", string(stdErrBytes), err)
	}

	log.Println(string(stdoutBytes))
	return nil
}

func parseInputArguments(ovmsClientConf OvmsClientConfig) []string {
	inputArgs := []string{}
	trimmedArgs := strings.TrimSpace(ovmsClientConf.OvmsClient.PipelineInputArgs)
	if len(trimmedArgs) > 0 {
		// arguments in command is space delimited
		return strings.Split(trimmedArgs, commandLineArgsDelimiter)
	}
	return inputArgs
}

func (flags *Flags) readPipelineConfig() ([]byte, error) {
	var contents []byte
	var err error

	pipelineConfig := filepath.Join(resourceDir, pipelineConfigFileName)
	pipelineProfile := strings.TrimSpace(os.Getenv(pipelineProfileEnv))
	// if pipelineProfile is empty, then will default to the current folder
	if len(pipelineProfile) == 0 {
		log.Printf("Loading configuration yaml file from %s folder...", flags.configDir)
		pipelineConfig = filepath.Join(flags.configDir, pipelineConfig)
	} else {
		log.Println("pipelineProfile: ", pipelineProfile)
		pipelineConfig = filepath.Join(flags.configDir, resourceDir, pipelineProfile, pipelineConfigFileName)
	}

	contents, err = os.ReadFile(pipelineConfig)
	if err != nil {
		err = fmt.Errorf("readPipelineConfig error with pipelineConfig: %v, environment variable key for pipelineProfile: %v, error: %v",
			pipelineConfig, pipelineProfileEnv, err)
	}

	return contents, err
}
