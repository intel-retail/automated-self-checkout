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
	scriptDir = "/scripts"
)

type OvmsClientInfo struct {
	PipelineScript    string
	PipelineInputArgs string
}
type OvmsClientConfig struct {
	OvmsClient OvmsClientInfo
}

func main() {
	// load config yaml from file
	log.Println("Loading configuration yaml file from ./res folder...")
	contents, err := os.ReadFile("./res/configuration.yaml")
	if err != nil {
		log.Fatalf("failed to read configuration yaml file from ./res folder: %v\n", err)
	}

	data := make(map[string]any)
	err = yaml.Unmarshal(contents, &data)
	if err != nil {
		log.Fatalf("failed to unmarshal configuration file configuration.yaml: %v\n", err)
	}

	log.Println("data: ", data)

	// convert to struct
	jsonBytes, err := json.Marshal(data)
	if err != nil {
		log.Fatalf("could not marshal map to JSON: %v\n", err)
	}

	var ovmsClientConf OvmsClientConfig
	if err := json.Unmarshal(jsonBytes, &ovmsClientConf); err != nil {
		log.Fatalf("could not unmarshal JSON data to %T: %v", ovmsClientConf, err)
	}

	log.Println("successfully converted to OvmsClientConfig struct", ovmsClientConf)

	//launch the pipeline script from the config
	if err := launchPipelineScript(ovmsClientConf); err != nil {
		log.Fatalf("found error while launching pipeline script: %v\n", err)
	}
}

func launchPipelineScript(ovmsClientConf OvmsClientConfig) error {
	scriptFilePath := filepath.Join(scriptDir, ovmsClientConf.OvmsClient.PipelineScript)
	inputArgs := parseInputArguments(ovmsClientConf)
	// if running in stream density mode, then the executable is the stream_density shell script itself with input
	streamDensityMode := os.Getenv("STREAM_DENSITY_MODE")
	if streamDensityMode == "1" {
		log.Println("in stream density mode!")
		scriptFilePath = "/home/pipeline-server/stream_density_framework-pipelines.sh"
		inputArgs = []string{filepath.Join(scriptDir, ovmsClientConf.OvmsClient.PipelineScript)}
	}

	executable, err := exec.LookPath(scriptFilePath)
	if err != nil {
		return fmt.Errorf("failed to get pipeline executable path: %v\n", err)
	}

	log.Println("running executable:", executable)
	cmd := exec.Command(executable, inputArgs...)
	cmd.Env = os.Environ()
	envs := cmd.Env
	for _, env := range envs {
		log.Println("environment variable: ", env)
	}
	if len(envs) == 0 {
		log.Println("empty environment variable")
	}

	stdout, err := cmd.StdoutPipe()
	if err != nil {
		return fmt.Errorf("failed to get the standard output from executable: %v\n", err)
	}
	if err := cmd.Start(); err != nil {
		return fmt.Errorf("failed to start the pipeline executable: %v\n", err)
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
		return strings.Split(trimmedArgs, " ")
	}
	return inputArgs
}
