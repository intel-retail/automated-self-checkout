/*********************************************************************
 * Copyright (c) Intel Corporation 2023
 * SPDX-License-Identifier: Apache-2.0
 **********************************************************************/

package ovms

import (
	"fmt"

	"gocv.io/x/gocv"
)

type TensorOutput struct {
	//name  string
	shape []int64
	data  *gocv.Mat
}

type TensorOutputs struct {
	RawData    [][]byte
	DataShapes [][]int64
	outputs    []TensorOutput
}

func NewTensorOutputs(rawBytes [][]byte, dataShapes [][]int64) *TensorOutputs {
	return &TensorOutputs{
		RawData:    rawBytes,
		DataShapes: dataShapes,
		outputs:    []TensorOutput{},
	}
}

func (tOutputs *TensorOutputs) GetOutputs() []TensorOutput {
	return tOutputs.outputs
}

func (tOutputs *TensorOutputs) ParseRawData() error {
	lenOfShapes := len(tOutputs.DataShapes)

	if lenOfShapes != len(tOutputs.RawData) {
		return fmt.Errorf("len of data shapes and rawdata do not match")
	}

	for i := 0; i < lenOfShapes; i++ {
		rows := int(tOutputs.DataShapes[i][1] * tOutputs.DataShapes[i][2] * tOutputs.DataShapes[i][3])
		dataMat, err := gocv.NewMatFromBytes(rows, 1, gocv.MatTypeCV32F, tOutputs.RawData[i])
		if err != nil {
			return fmt.Errorf("failed to create gocv.Mat from bytes")
		}

		tensorOutput := TensorOutput{
			shape: tOutputs.DataShapes[i],
			data:  &dataMat,
		}

		tOutputs.outputs = append(tOutputs.outputs, tensorOutput)

	}
	return nil
}

func (tensor *TensorOutput) ToFloat32() ([]float32, error) {
	return tensor.data.DataPtrFloat32()
}

func (tensor *TensorOutput) GetData() *gocv.Mat {
	return tensor.data
}

func (tensor *TensorOutput) GetShape() []int64 {
	return tensor.shape
}
