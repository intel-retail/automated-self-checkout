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

package server

import (
	"encoding/json"
	"fmt"
	"os"
	"path/filepath"
)

type DeviceUpdater struct {
	templateConfigJsonDir      string
	templateConfigJsonFileName string
}

type OvmsConfig struct {
	ModelList      []ModelConfig            `json:"model_config_list"`
	CustomNode     []map[string]interface{} `json:"custom_node_library_config_list"`
	PipelineConfig []map[string]interface{} `json:"pipeline_config_list"`
}

type ModelConfig struct {
	Config map[string]interface{} `json:"config"`
}

func NewDeviceUpdater(templateConfigJsonDir, templateConfigJsonFileName string) *DeviceUpdater {
	return &DeviceUpdater{
		templateConfigJsonDir:      templateConfigJsonDir,
		templateConfigJsonFileName: templateConfigJsonFileName,
	}
}

// UpdateDeviceAndCreateJson replaces {target_device} place-holder value with the input targeDevice value in the template config json file and
// produces a new config json file based on the input newConfigJsonFile;
// it returns error if failed to parse json or failed to produce a new config json file
func (du *DeviceUpdater) UpdateDeviceAndCreateJson(targetDevice, newConfigJsonFile string) error {
	templateConfigJsonFile := filepath.Join(du.templateConfigJsonDir, du.templateConfigJsonFileName)
	contents, err := os.ReadFile(templateConfigJsonFile)
	if err != nil {
		return fmt.Errorf("DeviceUpdater failed to read OVMS template config json file %s: %v", templateConfigJsonFile, err)
	}

	var data OvmsConfig
	err = json.Unmarshal(contents, &data)
	if err != nil {
		return fmt.Errorf("DeviceUpdater parsing OVMS template config json error: %v", err)
	}

	for _, modelConfig := range data.ModelList {
		modelConfig.Config["target_device"] = targetDevice
	}

	updateConfig, err := json.MarshalIndent(data, "", "    ")
	if err != nil {
		return fmt.Errorf("DeviceUpdater could not marshal config to JSON: %v", err)
	}

	if err := os.WriteFile(newConfigJsonFile, updateConfig, 0644); err != nil {
		return fmt.Errorf("DeviceUpdater could not write a updated config to a new JSON: %v", err)
	}

	return nil
}
