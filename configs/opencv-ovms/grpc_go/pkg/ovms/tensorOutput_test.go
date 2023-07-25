/*********************************************************************
 * Copyright (c) Intel Corporation 2023
 * SPDX-License-Identifier: Apache-2.0
 **********************************************************************/

package ovms

import (
	"bytes"
	"encoding/binary"
	"fmt"
	"testing"
)

func helper_float32toByte(f float64) []byte {
	float32Val := float32(f)
	var buf bytes.Buffer
	err := binary.Write(&buf, binary.LittleEndian, float32Val)
	if err != nil {
		fmt.Println("binary.Write failed:", err)
	}
	return buf.Bytes()
}

func TestTensorOutputs_ParseRawData(t *testing.T) {
	type fields struct {
		rawData    [][]byte
		dataShapes [][]int64
		outputs    []TensorOutput
	}
	tests := []struct {
		name    string
		fields  fields
		wantErr bool
	}{
		// TODO: Add test cases.
		{
			name: "happy Path",
			fields: fields{
				rawData: [][]byte{
					helper_float32toByte(0.5),
				},
				dataShapes: [][]int64{
					{1, 1, 1},
				},
			},
			wantErr: false,
		},
		{
			name: "len of shape and rawoutput mismatch",
			fields: fields{
				rawData: [][]byte{
					helper_float32toByte(0.5),
					helper_float32toByte(0.5),
				},
				dataShapes: [][]int64{
					{1, 1, 2},
				},
			},
			wantErr: true,
		},
	}
	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			tOutputs := &TensorOutputs{
				RawData:    tt.fields.rawData,
				DataShapes: tt.fields.dataShapes,
				outputs:    tt.fields.outputs,
			}
			if err := tOutputs.ParseRawData(); (err != nil) != tt.wantErr {
				t.Errorf("TensorOutputs.ParseRawData() error = %v, wantErr %v", err, tt.wantErr)
			}
		})
	}
}
