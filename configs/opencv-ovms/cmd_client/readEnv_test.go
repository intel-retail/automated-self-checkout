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
	"testing"

	"github.com/stretchr/testify/require"
)

func TestReadEnvs(t *testing.T) {
	tests := []struct {
		name            string
		envFileDir      string
		envFilesToTest  []string
		expectedEnvList []string
	}{
		{"valid EnvFilePath with no envfile", "./testdata", nil, nil},
		{"valid EnvFilePath with empty env", "./testdata", []string{"empty.env"}, nil},
		{"valid EnvFilePath with some envs", "./testdata", []string{"empty.env", "test.env"}, []string{"TESTKEY1=TESTVALUE1", "TESTKEY2=TESTVALUE2"}},
		{"invalid EnvFilePath", "./notfound", []string{"empty.env", "test.env"}, nil},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			log.Println(tt.envFileDir)
			client := OvmsClientInfo{
				EnvironmentVariableFiles: tt.envFilesToTest,
			}

			result := client.readClientEnvs(tt.envFileDir)
			require.Equal(t, tt.expectedEnvList, result)

			server := OvmsServerInfo{
				EnvironmentVariableFiles: tt.envFilesToTest,
			}
			result = server.readServerEnvs(tt.envFileDir)
			require.Equal(t, tt.expectedEnvList, result)
		})
	}
}
