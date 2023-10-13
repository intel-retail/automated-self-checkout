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
	"strings"
)

const (
	DOT_ENV_DIR               = "/tmp"
	DOT_ENV_FILE_NAME_PATTERN = ".env_*"

	ignored      = ""
	envDelimiter = "="
)

type TmpEnvFileWriter struct {
	envList []string
	envFile *os.File
}

func NewTmpEnvFileWriter(envList []string) *TmpEnvFileWriter {
	return &TmpEnvFileWriter{
		envList: envList,
	}
}

func (f *TmpEnvFileWriter) writeEnvs() error {
	if len(f.envList) == 0 {
		log.Println("No envs to write")
		return nil
	}

	//f.envList = testMultiLinesEnv(f.envList)

	// Create a temporary .env file
	envFile, err := os.CreateTemp(DOT_ENV_DIR, DOT_ENV_FILE_NAME_PATTERN)
	if err != nil {
		return fmt.Errorf("could not create temp %s file: %v", DOT_ENV_FILE_NAME_PATTERN, err)
	}

	log.Println("start writing envs into tmp env file:", envFile.Name())
	for _, envStr := range f.envList {
		log.Println("envStr:", envStr)
		// scrutinizing the env list for those values having multiple lines to replace \\n with \n
		envStr = convertMultiNewLines(envStr)
		if len(envStr) == 0 {
			continue
		}

		_, err = envFile.WriteString(fmt.Sprintln(envStr))
		if err != nil {
			return fmt.Errorf("failed to write temp %s file: %v", DOT_ENV_FILE_NAME_PATTERN, err)
		}
	}

	defer func() error {
		err = envFile.Close()
		if err != nil {
			return fmt.Errorf("failed to close temp %s file: %v", DOT_ENV_FILE_NAME_PATTERN, err)
		}
		return nil
	}()

	log.Printf("The temp %s file is created", envFile.Name())
	f.envFile = envFile

	return err
}

func convertMultiNewLines(envStr string) string {
	newEnvStr := envStr
	keyValue := strings.SplitN(envStr, envDelimiter, 2)
	if len(keyValue) != 2 {
		log.Printf("Corrupted key-value pair %s from environment variable, ignored", keyValue)
		return ignored
	}

	excludeEnvKeys := map[string]bool{
		"BASH_FUNC_which%%": true,
		"PATH":              true,
		"HOME":              true,
		"PWD":               true,
		"USER":              true,
	}

	key := keyValue[0]
	value := keyValue[1]

	if _, exists := excludeEnvKeys[key]; exists {
		log.Printf("env key %s is in exclude list, ignored", key)
		return ignored
	}

	newLine := fmt.Sprintln()
	if strings.Contains(value, newLine) {
		log.Printf("found new line for env %s, converting to \n literal", key)
		newVal := strings.ReplaceAll(value, newLine, "\\n")
		newEnvStr = strings.Join([]string{key, newVal}, envDelimiter)
	}
	return newEnvStr
}

func (f *TmpEnvFileWriter) cleanFile() error {
	return os.Remove(f.envFile.Name())
}

func testMultiLinesEnv(envList []string) []string {
	testEnv := `MULTI_LINE_ENV%%=() { ( alias; 
	  eval ${which_declare} ) | /usr/bin/which

		}`

	if err := os.Setenv("MULTI_LINE_ENV%%", testEnv); err != nil {
		log.Println("DEBUG:   failed to set multiple line env")
	}

	envList = append(envList, testEnv)
	return envList
}
