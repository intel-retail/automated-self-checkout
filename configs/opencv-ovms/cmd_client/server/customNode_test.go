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
	"os"
	"testing"

	"github.com/stretchr/testify/require"
)

func TestCustomNodes(t *testing.T) {
	tests := []struct {
		name                  string
		customNodeJsonFile    string
		templateJsonFileDir   string
		templateJsonFileName  string
		newJsonFileName       string
		expectError           bool
		expectedCustomNodeLib string
	}{
		{"add a new test custom node", "./test-yolov8_custom_node.json", ".", "test-update-device.json", "./add-test-yolov8.json", false, "/ovms/lib/libcustom_node_efficientnetb0-yolov8.so"},
		{"replacing an existing custom node", "./test-yolov8_custom_node.json", ".", "test-customnode.json", "./a-replacing-test-yolov8.json", false, "/ovms/lib/libcustom_node_efficientnetb0-yolov8.so"},
		{"non-existing custom node file", "./non-existing", ".", "test-update-device.json", "./failed-non-existing.json", true, ""},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			customNodeUpdater := NewCustomNodeUpdater(tt.customNodeJsonFile, tt.templateJsonFileDir, tt.templateJsonFileName)

			err := customNodeUpdater.UpdateCustomNode(tt.newJsonFileName)
			defer func() {
				_ = os.Remove(tt.newJsonFileName)
			}()

			if !tt.expectError {
				require.NoError(t, err)
				require.NotEmpty(t, customNodeUpdater)
				require.FileExists(t, tt.newJsonFileName)
				newData, readErr := os.ReadFile(tt.newJsonFileName)
				require.NoError(t, readErr)
				require.Contains(t, string(newData), "\"base_path\": \""+tt.expectedCustomNodeLib+"\"")
				if tt.templateJsonFileName == "test-customnode.json" {
					require.Contains(t, string(newData), "\"custom_node_library_config_list\":")
					require.Contains(t, string(newData), "\"pipeline_config_list\":")
				}
			} else {
				require.Error(t, err)
			}
		})
	}
}
