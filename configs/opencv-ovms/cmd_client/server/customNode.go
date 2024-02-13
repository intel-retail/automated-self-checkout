// ----------------------------------------------------------------------------------
// Copyright 2024 Intel Corp.
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

type CustomNodeUpdater struct {
	customNodeConfigJsonFile   string
	templateConfigJsonDir      string
	templateConfigJsonFileName string
}

type OvmsCustomNodeConfig struct {
	CustomNode     []map[string]interface{} `json:"custom_node_library_config_list"`
	PipelineConfig []map[string]interface{} `json:"pipeline_config_list"`
}

func NewCustomNodeUpdater(customNodeConfigJsonFile string, templateConfigJsonDir, templateConfigJsonFileName string) *CustomNodeUpdater {
	return &CustomNodeUpdater{
		customNodeConfigJsonFile:   customNodeConfigJsonFile,
		templateConfigJsonDir:      templateConfigJsonDir,
		templateConfigJsonFileName: templateConfigJsonFileName,
	}
}

// UpdateCustomNode adds (if not exists) or updates custom_node_library_config_list and related json information from customNodeConfigJsonFile into
// the template config json file  and then produces a new config json file based on the input newConfigJsonFile;
// it returns error if failed to parse json or failed to produce a new config json file
func (cu *CustomNodeUpdater) UpdateCustomNode(newConfigJsonFile string) error {
	templateConfigJsonFile := filepath.Join(cu.templateConfigJsonDir, cu.templateConfigJsonFileName)
	contents, err := os.ReadFile(templateConfigJsonFile)
	if err != nil {
		return fmt.Errorf("CustomNodeUpdater failed to read OVMS template config json file %s: %v", templateConfigJsonFile, err)
	}

	var ovmsConfigData OvmsConfig
	err = json.Unmarshal(contents, &ovmsConfigData)
	if err != nil {
		return fmt.Errorf("CustomNodeUpdater parsing OVMS template config json error: %v", err)
	}

	// read also the customNodeConfigJsonFile:
	customNodeConfig, err := os.ReadFile(cu.customNodeConfigJsonFile)
	if err != nil {
		return fmt.Errorf("CustomNodeUpdater failed to read OVMS custom node json file %s: %v", cu.customNodeConfigJsonFile, err)
	}

	var customNodeData OvmsCustomNodeConfig
	err = json.Unmarshal(customNodeConfig, &customNodeData)
	if err != nil {
		return fmt.Errorf("CustomNodeUpdater parsing OVMS custom node json error: %v", err)
	}

	if len(customNodeData.CustomNode) > 0 {
		// replacing:
		ovmsConfigData.CustomNode = customNodeData.CustomNode
		ovmsConfigData.PipelineConfig = customNodeData.PipelineConfig
	}

	updateConfig, err := json.MarshalIndent(ovmsConfigData, "", "    ")
	if err != nil {
		return fmt.Errorf("CustomNodeUpdater could not marshal config to JSON: %v", err)
	}

	if err := os.WriteFile(newConfigJsonFile, updateConfig, 0644); err != nil {
		return fmt.Errorf("CustomNodeUpdater could not write a updated config to a new JSON: %v", err)
	}

	return nil
}
