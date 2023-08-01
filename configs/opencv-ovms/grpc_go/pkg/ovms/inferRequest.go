/*********************************************************************
 * Copyright (c) Intel Corporation 2023
 * SPDX-License-Identifier: Apache-2.0
 **********************************************************************/

package ovms

import (
	"context"
	"fmt"
	"time"

	grpc_client "videoProcess/grpc-client"
)

var (
	defaultInputShape = []int64{1, 416, 416, 3}
)

func ModelInferRequest(client grpc_client.GRPCInferenceServiceClient, image []float32, modelName string, modelVersion string) (*TensorOutputs, error) {
	// Create context for our request with 10 second timeout
	ctx, cancel := context.WithTimeout(context.Background(), 10*time.Second)
	defer cancel()

	// Create request input tensors
	inferInputs := []*grpc_client.ModelInferRequest_InferInputTensor{
		&grpc_client.ModelInferRequest_InferInputTensor{
			Name:     "images",
			Datatype: "FP32",
			Shape:    defaultInputShape,
			Contents: &grpc_client.InferTensorContents{
				Fp32Contents: image,
			},
		},
	}

	// Create inference request for specific model/version
	modelInferRequest := grpc_client.ModelInferRequest{
		ModelName:    modelName,
		ModelVersion: modelVersion,
		Inputs:       inferInputs,
	}

	// Submit inference request to server
	modelInferResponse, err := client.ModelInfer(ctx, &modelInferRequest)
	if err != nil {
		// we don't want the pipeline to quit due to log.Fatal's exit
		fmt.Println("Error processing InferRequest: ", err)
		return nil, fmt.Errorf("Error on processing InferRequest: %v", err)
	}

	responseOutputs := TensorOutputs{
		RawData:    modelInferResponse.RawOutputContents,
		DataShapes: GetAllShapes(modelInferResponse),
	}

	responseOutputs.ParseRawData()
	return &responseOutputs, nil
}
