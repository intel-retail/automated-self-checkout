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
)

const (
	DOT_ENV_DIR               = "/tmp"
	DOT_ENV_FILE_NAME_PATTERN = ".env_*"

	emptyFileName = ""
	envDelimiter  = "="
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

	// Create a temporary .env file
	envFile, err := os.CreateTemp(DOT_ENV_DIR, DOT_ENV_FILE_NAME_PATTERN)
	if err != nil {
		return fmt.Errorf("could not create temp %s file: %v", DOT_ENV_FILE_NAME_PATTERN, err)
	}

	log.Println("start writing envs into tmp env file:", envFile.Name())
	for _, envStr := range f.envList {
		log.Println("envStr:", envStr)
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

func (f *TmpEnvFileWriter) cleanFile() error {
	return os.Remove(f.envFile.Name())
}
