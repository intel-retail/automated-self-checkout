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
	"os"
	"testing"

	"github.com/stretchr/testify/require"
)

func TestParse(t *testing.T) {
	tests := []struct {
		name            string
		jsonFileDir     string
		jsonFileName    string
		targetDevice    string
		newJsonFileName string
		expectError     bool
	}{
		{"update test template json file", ".", "test-update-device.json", "GPU.0", "./a-new-test-update-device.json", false},
		{"invalid json content", ".", "test-invalid.json", "GPU", "", true},
		{"non-existing json file", ".", "non-existing.json", "GPU", "", true},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			deviceUpdater := NewDeviceUpdater(tt.jsonFileDir, tt.jsonFileName)

			err := deviceUpdater.UpdateDeviceAndCreateJson(tt.targetDevice, tt.newJsonFileName)
			defer func() {
				_ = os.Remove(tt.newJsonFileName)
			}()

			if !tt.expectError {
				require.NoError(t, err)
				require.NotEmpty(t, deviceUpdater)
				require.FileExists(t, tt.jsonFileName)
				newData, readErr := os.ReadFile(tt.newJsonFileName)
				require.NoError(t, readErr)
				require.Contains(t, string(newData), "\"target_device\":\""+tt.targetDevice+"\"")
			} else {
				require.Error(t, err)
			}
		})
	}
}
