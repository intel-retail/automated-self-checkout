/*********************************************************************
 * Copyright (c) Intel Corporation 2023
 * SPDX-License-Identifier: Apache-2.0
 **********************************************************************/

package main

import (
	"fmt"
	"image"
	"image/color"
	"log"
	"net/http"
	"os"
	"time"
	grpc_client "videoProcess/grpc-client"
	"videoProcess/pkg/ovms"
	"videoProcess/pkg/yolov5"
	"videoProcess/utilities"

	"github.com/hybridgroup/mjpeg"
	"gocv.io/x/gocv"
	"google.golang.org/grpc"
)

const (
	RETRY = time.Millisecond
)

func main() {
	FLAGS := utilities.ParseFlags()

	webcam, err := gocv.OpenVideoCapture(FLAGS.InputSrc) //  /dev/video4
	if err != nil {
		errMsg := fmt.Errorf("faile to open device: %s", FLAGS.InputSrc)
		fmt.Println(errMsg)
	}
	defer webcam.Close()

	camHeight := float32(webcam.Get(gocv.VideoCaptureFrameHeight))
	camWidth := float32(webcam.Get(gocv.VideoCaptureFrameWidth))

	img := gocv.NewMat()
	defer img.Close()

	// // Connect to gRPC server
	conn, err := grpc.Dial(FLAGS.URL, grpc.WithInsecure())
	if err != nil {
		log.Fatalf("Couldn't connect to endpoint %s: %v", FLAGS.URL, err)
	}
	defer conn.Close()

	// // Create client from gRPC server connection
	client := grpc_client.NewGRPCInferenceServiceClient(conn)

	// create the mjpeg stream
	stream := mjpeg.NewStream()

	go runModelServer(&client, webcam, &img, FLAGS.ModelName, FLAGS.ModelVersion, stream, camWidth, camHeight, FLAGS.Output)
	fmt.Println("Capturing. Point your browser to " + FLAGS.Host)

	// start http server
	http.Handle("/", stream)
	log.Fatal(http.ListenAndServe(FLAGS.Host, nil))

}

func runModelServer(client *grpc_client.GRPCInferenceServiceClient, webcam *gocv.VideoCapture, img *gocv.Mat, modelname string,
	modelVersion string, stream *mjpeg.Stream, camWidth float32, camHeight float32, output string) {
	var aggregateLatencyAfterInfer float64
	var aggregateLatencyAfterFinalProcess float64
	var frameNum float64

	// output latency metic to txt
	latencyMetricFile := output + "/latency.txt"
	file, err := os.Create(latencyMetricFile)
	if err != nil {
		fmt.Printf("failed to write to file:%v", err)
	}
	defer file.Close()

	for webcam.IsOpened() {
		if ok := webcam.Read(img); !ok {
			// retry once after 1 millisecond
			time.Sleep(RETRY)
			continue
		}
		if img.Empty() {
			continue
		}
		frameNum++

		fp32Image := gocv.NewMat()
		defer fp32Image.Close()

		// resize image to yolov5 model specifications
		gocv.Resize(*img, &fp32Image, image.Point{int(yolov5.Input_shape[1]), int(yolov5.Input_shape[2])}, 0, 0, 3)

		// convert to image matrix to use float32
		fp32Image.ConvertTo(&fp32Image, gocv.MatTypeCV32F)
		imgToBytes, _ := fp32Image.DataPtrFloat32()

		start := float64(time.Now().UnixMilli())
		inferResponse := ovms.ModelInferRequest(*client, imgToBytes, modelname, modelVersion)
		afterInfer := float64(time.Now().UnixMilli())
		aggregateLatencyAfterInfer += afterInfer - start

		latencyStr := fmt.Sprintf("latency after infer: %v\n", aggregateLatencyAfterInfer/frameNum)
		_, err = file.WriteString(latencyStr)
		if err != nil {
			fmt.Printf("failed to write to file:%v", err)
		}

		// fmt.Printf("latency after infer: %v\n", afterInfer-start)

		detectedObjects := yolov5.DetectedObjects{}

		// temp code:
		output := ovms.TensorOutputs{
			RawData:    [][]byte{inferResponse.RawData[0]},
			DataShapes: [][]int64{inferResponse.DataShapes[0]},
		}
		output.ParseRawData()
		err := detectedObjects.Postprocess(output, camWidth, camHeight)
		if err != nil {
			fmt.Printf("post process failed: %v\n", err)
		}
		fmt.Printf("length of detectedObjects after  processing: %v\n", len(detectedObjects.Objects))
		detectedObjects = detectedObjects.FinalPostProcessAdvanced()
		// debug
		fmt.Printf("length of detectedObjects after final processing: %v\n", len(detectedObjects.Objects))

		// Print after processing latency
		afterFinalProcess := float64(time.Now().UnixMilli())
		aggregateLatencyAfterFinalProcess += afterFinalProcess - start
		latencyStr = fmt.Sprintf("average latency after final process: %v\n", aggregateLatencyAfterFinalProcess/frameNum)
		_, err = file.WriteString(latencyStr)
		if err != nil {
			fmt.Printf("failed to write to file:%v", err)
		}

		// fmt.Printf("latency after final process: %v\n", afterFinalProcess-start)

		// add bounding boxes to resixed image
		detectedObjects.AddBoxesToFrame(&fp32Image, color.RGBA{0, 255, 0, 0}, camWidth, camWidth)

		buf, _ := gocv.IMEncode(".jpg", fp32Image)
		stream.UpdateJPEG(buf.GetBytes())
		buf.Close()

	}

}
