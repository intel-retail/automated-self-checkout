/*********************************************************************
 * Copyright (c) Intel Corporation 2023
 * SPDX-License-Identifier: Apache-2.0
 **********************************************************************/

package yolov5

import (
	"image"
	"image/color"
	"sort"

	"videoProcess/pkg/ovms"
	"videoProcess/utilities"

	"gocv.io/x/gocv"
)

type DetectedObject struct {
	frameId    int
	x          float32
	y          float32
	width      float32
	height     float32
	confidence float32
	classId    int
	classText  string
}

type DetectedObjects struct {
	Objects              []DetectedObject
	scale_h              float32
	scale_w              float32
	boundingBoxThickness int
}

func (dObj *DetectedObject) BoundingBox(camWidth float32,
	camHeight float32) image.Rectangle {

	return image.Rect(
		int(dObj.x*(416.0/camWidth)),
		int(dObj.y*(416.0/camHeight)),
		int((dObj.x+dObj.width)*(416.0/camWidth)),
		int((dObj.y+dObj.height)*(416.0/camHeight)),
	)

}

func (dObj *DetectedObject) GetConfidence() float32 {
	return dObj.confidence
}
func (dObj *DetectedObject) GetClassId() int {
	return dObj.classId
}
func (dObj *DetectedObject) GetClassText() string {
	return dObj.classText
}
func (dObj *DetectedObject) GetFrameId() int {
	return dObj.frameId
}

func (dObjs *DetectedObjects) AddBoxesToFrame(frame *gocv.Mat, boxColor color.RGBA, camWidth float32, camHeight float32) {
	for _, obj := range dObjs.Objects {
		gocv.Rectangle(frame,
			obj.BoundingBox(camWidth, camHeight),
			boxColor,
			dObjs.boundingBoxThickness)
	}

}

func (dObjs *DetectedObjects) intersectionOverUnion(object1 DetectedObject, object2 DetectedObject) float32 {
	var intersectionArea float32

	overlappingWidth := utilities.Min(object1.x+object1.width, object2.x+object2.width) - utilities.Max(object1.x, object2.x)
	overlappingHeight := utilities.Min(object1.y+object1.height, object2.y+object2.height) - utilities.Max(object1.y, object2.y)

	if overlappingWidth < 0 || overlappingHeight < 0 {
		intersectionArea = 0
	} else {
		intersectionArea = overlappingHeight * overlappingWidth
	}
	unionArea := object1.width*object1.height + object2.width*object2.height - intersectionArea
	return intersectionArea / unionArea
}

func (dObjs *DetectedObjects) FinalPostProcessClassic() DetectedObjects {
	// Classic postprocessing
	sort.SliceStable(dObjs.Objects, func(i, j int) bool {
		return dObjs.Objects[i].confidence > dObjs.Objects[j].confidence
	})

	outDetectedResults := DetectedObjects{}

	for i := 1; i < len(dObjs.Objects); i++ {
		if dObjs.Objects[i].confidence == 0 {
			continue
		}
		for j := i + 1; j < len(dObjs.Objects); j++ {
			if dObjs.intersectionOverUnion(dObjs.Objects[i], dObjs.Objects[j]) >= boxiou_threshold {
				dObjs.Objects[j].confidence = 0
			}
			outDetectedResults.Objects = append(outDetectedResults.Objects, dObjs.Objects[i])
		}

	}
	return outDetectedResults
}

func (dObjs *DetectedObjects) FinalPostProcessAdvanced() DetectedObjects {
	// Advanced postprocessing
	// Checking IOU threshold conformance
	// For every i-th object we're finding all objects it intersects with, and comparing confidence
	// If i-th object has greater confidence than all others, we include it into result
	outDetectedResults := DetectedObjects{}
	for _, obj1 := range dObjs.Objects {

		isGoodResult := true
		for _, obj2 := range dObjs.Objects {
			if obj1.classId == obj2.classId && obj1.confidence < obj2.confidence &&
				dObjs.intersectionOverUnion(obj1, obj2) >= boxiou_threshold { // if obj1 is the same as obj2, condition
				// expression will evaluate to false anyway
				isGoodResult = false
				break
			}
		}
		if isGoodResult {
			outDetectedResults.Objects = append(outDetectedResults.Objects, obj1)
		}

	}
	return outDetectedResults
}

func (dObjs *DetectedObjects) calculateEntryIndex(totalCells int, lcoords int, lclasses int, location int, entry int) int {
	n := location / totalCells
	loc := location % totalCells
	return (n*(lcoords+lclasses)+entry)*totalCells + loc
}

func (dObjs *DetectedObjects) getClassLabelText(classIndex int) string {
	if classIndex > 80 {
		return ""
	}

	return Labels[classIndex]
}

func (dObjs *DetectedObjects) Postprocess(tensorOutputs ovms.TensorOutputs, camWidth float32, camHeight float32) error {
	regionCoordsCount := 3
	regionNum := 3
	original_im_w := camWidth
	original_im_h := camHeight
	for _, tensor := range tensorOutputs.GetOutputs() {

		sideH := int(tensor.GetShape()[2]) // int(output_shape[2])
		sideW := int(tensor.GetShape()[3]) // int(output_shape[3])

		scaleH := int(Input_shape[1])
		scaleW := int(Input_shape[2])

		entriesNum := sideW * sideH
		outData, _ := tensor.ToFloat32()
		for i := 1; i < entriesNum; i++ {
			row := i / sideW
			col := i % sideW
			for n := 1; n < regionNum; n++ {

				obj_index := dObjs.calculateEntryIndex(entriesNum, regionCoordsCount, classes+1 /* + confidence byte */, n*entriesNum+i, regionCoordsCount)
				box_index := dObjs.calculateEntryIndex(entriesNum, regionCoordsCount, classes+1, n*entriesNum+i, 0)
				outdata := outData[obj_index]
				scale := utilities.Sigmoid(outdata)

				if scale >= confidence_threshold {
					x := (float32(col) + utilities.Sigmoid(outData[box_index+0*entriesNum])) / float32(sideW) * float32(original_im_w)
					y := (float32(row) + utilities.Sigmoid(outData[box_index+1*entriesNum])) / float32(sideH) * float32(original_im_h)
					height := (utilities.ExpPow(outData[box_index+3*entriesNum]) * Anchors_13[2*n+1] * float32(original_im_h)) / float32(scaleH)
					width := utilities.ExpPow(outData[box_index+2*entriesNum]) * Anchors_13[2*n] * float32(original_im_w) / float32(scaleW)

					obj := DetectedObject{}
					obj.x = utilities.Clamp(x-width/2.0, 0.0, float32(original_im_w))
					obj.y = utilities.Clamp(y-height/2.0, 0.0, float32(original_im_h))
					obj.width = utilities.Clamp(width, 0.0, float32(original_im_w)-obj.x)
					obj.height = utilities.Clamp(height, 0.0, float32(original_im_h)-obj.y)

					for j := 1; j < classes; j++ {
						class_index := dObjs.calculateEntryIndex(entriesNum, regionCoordsCount, classes+1, n*entriesNum+i, regionCoordsCount+1+j)
						prob := scale * utilities.Sigmoid(outData[class_index])

						if prob >= confidence_threshold {
							obj.confidence = prob
							obj.classId = j
							obj.classText = dObjs.getClassLabelText(j)

							dObjs.Objects = append(dObjs.Objects, obj)

						}
					}

				}
			}
		}
	}
	return nil
}
