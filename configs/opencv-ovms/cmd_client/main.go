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
	"encoding/json"
	"flag"
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
	ENV_KEY_VALUE_DELIMITER = "="

	scriptDir                = "./scripts"
	envFileDir               = "./envs"
	pipelineProfileEnv       = "PIPELINE_PROFILE"
	resourceDir              = "res"
	pipelineConfigFileName   = "configuration.yaml"
	commandLineArgsDelimiter = " "
	streamDensityScript      = "./stream_density.sh"
)

type OvmsClientInfo struct {
	PipelineScript           string
	PipelineInputArgs        string
	PipelineStreamDensityRun string
	EnvironmentVariableFiles []string
}
type OvmsClientConfig struct {
	OvmsClient OvmsClientInfo
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

	// in order to do the environment override from the current existing cmd.Env,
	// we have to save this and then apply the overrides with the existing keys
	origEnvs := make([]string, len(cmd.Env))
	copy(origEnvs, cmd.Env)
	// apply all envs from env files if any
	envList := ovmsClientConf.OvmsClient.readEnvs(envFileDir)
	cmd.Env = append(cmd.Env, envList...)
	// override envs from the origEnvs
	cmd.Env = append(cmd.Env, origEnvs...)

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
