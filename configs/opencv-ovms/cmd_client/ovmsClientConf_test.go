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
	"log"
	"os"
	"os/exec"
	"strconv"
	"testing"
	"time"

	"github.com/stretchr/testify/require"
)

func TestSetEnvContainerCountAndGrpcPort(t *testing.T) {
	tests := []struct {
		name            string
		launchContainer func(t *testing.T)
		cleanup         func(t *testing.T)
		expectedCidCnt  string
	}{
		{"first time run", func(t *testing.T) {}, func(t *testing.T) {}, "0"},
		{"launch one dummy container and check", launchDummyContainer, cleanupDummyContainer, "1"},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			client := &OvmsClientConfig{
				OvmsClient: OvmsClientInfo{},
			}

			origCidEnv := os.Getenv(CID_COUNT_ENV)
			origGrpcPortEnv := os.Getenv(GRPC_PORT_ENV)

			tt.launchContainer(t)

			client.setEnvContainerCountAndGrpcPort()
			defer func() {
				tt.cleanup(t)
				os.Setenv(CID_COUNT_ENV, origCidEnv)
				os.Setenv(GRPC_PORT_ENV, origGrpcPortEnv)
			}()

			newCidCnt := os.Getenv(CID_COUNT_ENV)
			require.Equal(t, tt.expectedCidCnt, newCidCnt)

			newGrpcPort := os.Getenv(GRPC_PORT_ENV)
			require.NotEmpty(t, newGrpcPort)
			grpcPortNum, err := strconv.Atoi(newGrpcPort)
			require.NoError(t, err)
			require.True(t, grpcPortNum > defaultGrpcPortFrom)
		})
	}
}

func launchDummyContainer(t *testing.T) {
	dummyContainerName := "dummy" + profileLaunchedContainerNameSuffix
	dummyDockerCmd := exec.Command("docker", []string{"run", "--name", dummyContainerName, "busybox"}...)
	if err := dummyDockerCmd.Run(); err != nil {
		log.Printf("failed to launch dummy Docker container busybox with container name %s: %v", dummyContainerName, err)
		t.Fail()
	}
	time.Sleep(3)
}

func cleanupDummyContainer(t *testing.T) {
	dummyContainerName := "dummy" + profileLaunchedContainerNameSuffix
	dummyDockerCmd := exec.Command("docker", []string{"rm", dummyContainerName, "-f"}...)
	if err := dummyDockerCmd.Run(); err != nil {
		log.Printf("failed to clean up dummy Docker container busybox with container name %s: %v", dummyContainerName, err)
		t.Fail()
	}
}
