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

package parser

import (
	"encoding/json"
	"fmt"
	"io"
	"os"
	"path/filepath"
)

type ModelConfigInfo struct {
	ModelName string `json:"name"`
}

type ModelConfigListInfo struct {
	Config ModelConfigInfo `json:"config"`
}

type ConfigJsonModelParser struct {
	ModelConfigList []ModelConfigListInfo `json:"model_config_list"`

	configJsonFileName string
	configJsonDir      string
}

func NewConfigJsonModelParser(configJsonDir, configJsonFileName string) *ConfigJsonModelParser {
	return &ConfigJsonModelParser{
		configJsonDir:      configJsonDir,
		configJsonFileName: configJsonFileName,
	}
}

// Parse will parse the list of model names from the file configJsonFileName under the directory configJsonDir
func (cjmp *ConfigJsonModelParser) Parse() error {
	configJsonFile := filepath.Join(cjmp.configJsonDir, cjmp.configJsonFileName)
	jsonFileReader, err := os.Open(configJsonFile)
	if err != nil {
		return fmt.Errorf("failed to open OVMS config json file %s: %v", configJsonFile, err)
	}
	defer jsonFileReader.Close()

	contents, err := io.ReadAll(jsonFileReader)
	if err != nil {
		return fmt.Errorf("failed to read OVMS config json file %s: %v", configJsonFile, err)
	}

	if err := json.Unmarshal(contents, &cjmp); err != nil {
		return fmt.Errorf("failed to unmarshal OVMS config json: %v", err)
	}

	return nil
}
