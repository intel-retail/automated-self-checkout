package main

import (
	"encoding/json"
	"fmt"
	"io"
	"log"
	"os"
	"os/exec"
	"path/filepath"
	"strings"

	"gopkg.in/yaml.v3"
)

const (
	scriptDir                = "/scripts"
	pipelineProfileEnv       = "PIPELINE_PROFILE"
	resourceDir              = "res"
	pipelineConfigFileName   = "configuration.yaml"
	commandLineArgsDelimiter = " "
	streamDensityScript      = "/home/pipeline-server/stream_density_framework-pipelines.sh"
)

type OvmsClientInfo struct {
	PipelineScript           string
	PipelineInputArgs        string
	PipelineStreamDensityRun string
}
type OvmsClientConfig struct {
	OvmsClient OvmsClientInfo
}

func main() {
	// the config yaml file is in res/ folder of the "pipeline profile" directory
	contents, err := readPipelineConfig()
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

	var ovmsClientConf OvmsClientConfig
	if err := json.Unmarshal(jsonBytes, &ovmsClientConf); err != nil {
		log.Fatalf("could not unmarshal JSON data to %T: %v", ovmsClientConf, err)
	}

	log.Println("successfully converted to OvmsClientConfig struct", ovmsClientConf)

	//launch the pipeline script from the config
	if err := launchPipelineScript(ovmsClientConf); err != nil {
		log.Fatalf("found error while launching pipeline script: %v", err)
	}
}

func launchPipelineScript(ovmsClientConf OvmsClientConfig) error {
	scriptFilePath := filepath.Join(scriptDir, ovmsClientConf.OvmsClient.PipelineScript)
	inputArgs := parseInputArguments(ovmsClientConf)
	// if running in stream density mode, then the executable is the stream_density shell script itself with input
	streamDensityMode := os.Getenv("STREAM_DENSITY_MODE")
	pipelineStreamDensityRun := strings.TrimSpace(ovmsClientConf.OvmsClient.PipelineStreamDensityRun)
	if streamDensityMode == "1" {
		log.Println("in stream density mode!")
		if len(pipelineStreamDensityRun) == 0 {
			// when pipelineStreamDensityRun is empty string, then default to the original pipelineScript
			pipelineStreamDensityRun = filepath.Join(scriptDir, ovmsClientConf.OvmsClient.PipelineScript)
			scriptFilePath = streamDensityScript
			inputArgs = []string{filepath.Join(pipelineStreamDensityRun + commandLineArgsDelimiter +
				ovmsClientConf.OvmsClient.PipelineInputArgs)}
		}
	}

	executable, err := exec.LookPath(scriptFilePath)
	if err != nil {
		return fmt.Errorf("failed to get pipeline executable path: %v", err)
	}

	log.Println("running executable:", executable)
	cmd := exec.Command(executable, inputArgs...)
	cmd.Env = os.Environ()
	if streamDensityMode == "1" {
		cmd.Env = append(cmd.Env, "PipelineStreamDensityRun="+pipelineStreamDensityRun)
	}
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
	if err := cmd.Start(); err != nil {
		return fmt.Errorf("failed to start the pipeline executable: %v", err)
	}

	readBytes, _ := io.ReadAll(stdout)
	if err := cmd.Wait(); err != nil {
		return fmt.Errorf("found error while executing pipeline scripts: %v", err)
	}

	log.Println(string(readBytes))
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

func readPipelineConfig() ([]byte, error) {
	var contents []byte
	var err error
	pipelineConfig := filepath.Join(resourceDir, pipelineConfigFileName)
	pipelineProfile := strings.TrimSpace(os.Getenv(pipelineProfileEnv))
	// if pipelineProfile is empty, then will default to the current folder
	if len(pipelineProfile) == 0 {
		log.Println("Loading configuration yaml file from ./res folder...")
		pipelineConfig = filepath.Join(".", pipelineConfig)
	} else {
		log.Println("pipelineProfile: ", pipelineProfile)
		pipelineConfig = filepath.Join(resourceDir, pipelineProfile, pipelineConfigFileName)
	}

	contents, err = os.ReadFile(pipelineConfig)
	if err != nil {
		err = fmt.Errorf("readPipelineConfig error with pipelineConfig: %v, environment variable key for pipelineProfile: %v, error: %v",
			pipelineConfig, pipelineProfileEnv, err)
	}

	return contents, err
}
