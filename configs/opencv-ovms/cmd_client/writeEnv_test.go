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
	"fmt"
	"log"
	"os"
	"path/filepath"
	"strings"
	"testing"

	"github.com/stretchr/testify/require"
)

func TestWriteEnvs(t *testing.T) {
	readEnvFileDir := "./testdata"

	tests := []struct {
		name              string
		readEnvFileToTest []string
	}{
		{"valid write temp env file from test.env file", []string{"empty.env", "test.env"}},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			log.Println(readEnvFileDir)
			client := OvmsClientInfo{
				EnvironmentVariableFiles: tt.readEnvFileToTest,
			}
			envList := client.readClientEnvs(readEnvFileDir)

			if len(envList) == 0 {
				log.Println("empty env list")
			} else {
				for _, env := range envList {
					log.Println("env: ", env)
					keyValue := strings.SplitN(env, envDelimiter, 2)
					require.Equal(t, 2, len(keyValue))
					require.NoError(t, os.Setenv(keyValue[0], keyValue[1]))
				}
			}

			tmpEnv := NewTmpEnvFileWriter(envList)
			err := tmpEnv.writeEnvs()
			require.NoError(t, err)
			defer func() {
				err = tmpEnv.cleanFile()
				require.NoError(t, err)
			}()

			require.FileExists(t, tmpEnv.envFile.Name(), fmt.Sprintf("temp env file %s does not exist", tmpEnv.envFile.Name()))

			data, err := os.ReadFile(tmpEnv.envFile.Name())
			require.NoError(t, err)
			require.NotEmpty(t, data)

			log.Println("data:", string(data))

			// for those envs in envList we write out to .env file and we should expect to see
			// those envs are also in the .env files
			envs := string(data)
			for _, env := range envList {
				keyValue := strings.SplitN(env, envDelimiter, 2)
				require.Contains(t, envs, keyValue[0])
				require.Contains(t, envs, keyValue[1])
			}

			// verify that envs from the written file can be set into os envs:
			tempEnvClient := OvmsClientInfo{
				EnvironmentVariableFiles: []string{filepath.Base(tmpEnv.envFile.Name())},
			}
			tmpEnvList := tempEnvClient.readClientEnvs(DOT_ENV_DIR)
			require.NotEmpty(t, tmpEnvList)
			for _, env := range tmpEnvList {
				log.Println("env: ", env)
				keyValue := strings.SplitN(env, envDelimiter, 2)
				require.Equal(t, 2, len(keyValue))
				require.NoError(t, os.Setenv(keyValue[0], keyValue[1]))
			}
		})
	}
}
