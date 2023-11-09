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
	"log"
	"os"
	"path/filepath"
	"strings"
)

func (ovmsServer OvmsServerInfo) readServerEnvs(envFileDir string) (envList []string) {
	return readEnvs(envFileDir, ovmsServer.EnvironmentVariableFiles)
}

func (ovmsClient OvmsClientInfo) readClientEnvs(envFileDir string) (envList []string) {
	return readEnvs(envFileDir, ovmsClient.EnvironmentVariableFiles)
}

func readEnvs(envFileDir string, evnFileNames []string) (envList []string) {
	if len(evnFileNames) > 0 {
		log.Println("found env files to apply")
		for _, eachEnvFile := range evnFileNames {
			// load each file, parse the key value pair and append them into envs
			envFilePath := filepath.Join(envFileDir, eachEnvFile)
			envFileHdle, err := os.Open(envFilePath)
			if err != nil {
				log.Printf("Error- error found for reading env file %s: %v", envFilePath, err)
				// skipping applying envs for this envFilePath
				continue
			}
			defer envFileHdle.Close()

			reader := bufio.NewScanner(envFileHdle)
			reader.Split(envSplitFunc)

			for reader.Scan() {
				envKeyValue := reader.Text()
				log.Println("env key-value pair:", envKeyValue)
				envList = append(envList, envKeyValue)
			}

			for _, envItem := range envList {
				log.Println("envItem:", envItem)
			}
		}
		return envList
	}

	return
}

func envSplitFunc(contents []byte, atEOF bool) (advance int, token []byte, err error) {
	if atEOF && len(contents) == 0 {
		return 0, nil, nil
	}

	if atEOF {
		return len(contents), contents, nil
	}

	newLine := fmt.Sprintln()
	if i := strings.Index(string(contents), newLine); i >= 0 {
		// skip the new line delimiter
		return i + len(newLine), contents[0:i], nil
	}

	return
}
