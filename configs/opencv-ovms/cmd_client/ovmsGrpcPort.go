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
	"fmt"
	"io"
	"log"
	"os"
	"os/exec"
	"path/filepath"
	"strconv"
	"strings"
)

const (
	SERVER_CONTAINER_INSTANCE_ENV = "SERVER_CONTAINER_INSTANCE"
)

func getServerGrpcPort(srvContainerName string) (string, error) {
	os.Setenv(SERVER_CONTAINER_INSTANCE_ENV, srvContainerName)

	grpcPortScript := filepath.Join(scriptDir, "get_server_grpc_port.sh")
	script, err := exec.LookPath(grpcPortScript)
	if err != nil {
		return "", fmt.Errorf("failed to get server grpc port script path: %v", err)
	}

	log.Println("running get server grpc port script:", script)
	srvGrpcPortCmd := exec.Command(script)
	stdout, err := srvGrpcPortCmd.StdoutPipe()
	if err != nil {
		return "", fmt.Errorf("failed to get the output from script: %v", err)
	}
	stderr, err := srvGrpcPortCmd.StderrPipe()
	if err != nil {
		return "", fmt.Errorf("failed to get the error pipe from script: %v", err)
	}
	if err := srvGrpcPortCmd.Start(); err != nil {
		return "", fmt.Errorf("failed to start the script: %v", err)
	}

	portReader := bufio.NewReader(stdout)
	resBytes, _ := portReader.ReadString('\n')

	stdErrBytes, _ := io.ReadAll(stderr)
	if err := srvGrpcPortCmd.Wait(); err != nil {
		return "", fmt.Errorf("found error while executing get server grpc port scripts- stdErrMsg: %s, Err: %v", string(stdErrBytes), err)
	}

	srvPortNum := strings.TrimSuffix(string(resBytes), fmt.Sprintln())

	log.Printf("srvPortNum from OVMS server %s: %s", srvContainerName, srvPortNum)

	// verify it is an integer
	if len(srvPortNum) > 0 {
		// verify the output is an integer
		_, err := strconv.Atoi(srvPortNum)
		if err != nil {
			return "", fmt.Errorf("failed to parse the OVMS server port number for %s: %v", srvContainerName, err)
		}
	} else {
		return "", fmt.Errorf("srvPortNum is empty for %s, cannot continue", srvContainerName)
	}

	return srvPortNum, nil
}
