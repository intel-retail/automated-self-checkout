package ovms

import(
	grpc_client "videoProcess/grpc-client"
)


func GetAllShapes(response *grpc_client.ModelInferResponse) [][]int64 {
	shapes := [][]int64{}
	for _, output := range response.GetOutputs() {
		shapes = append(shapes, output.Shape)
	}
	return shapes
}
