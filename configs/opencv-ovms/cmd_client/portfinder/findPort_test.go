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

package portfinder

import (
	"log"
	"testing"

	"github.com/stretchr/testify/require"
)

func TestScan(t *testing.T) {
	tests := []struct {
		name string
		from int
	}{
		{"good free port at least bigger than defaultPort", defaultStartPort},
		{"good free port at least bigger than from", 0},
		{"good free port at least bigger than from a bigger", 35000},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			portFinder := PortFinder{
				IpAddress: "localhost",
			}

			result := portFinder.GetFreePortNumber(tt.from)
			log.Println("result=", result)
			require.True(t, result > tt.from)
		})
	}
}
