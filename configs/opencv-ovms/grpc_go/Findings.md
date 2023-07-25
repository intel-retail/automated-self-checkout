# OVMS+GOCV Findings

1. Fully capable of connecting to OVMS via Kserve API using GRPC
2. Able to send input to the model and receive the output from the model
3.  There is no blocks using this to communicate to OVMS using this method



## Drawbacks

1. YOLOV5 does not look to be supported by openvino
   - There are alot of post processing of the tensor output that needs to be done 
   - To get through this, team will need a through understanding of the model 



## Workarounds 

- If attempting to process yolov5 output
  - Reshape each tensor output to [1,3,52,52,85], [1,3,26,26,85], [1,3,13,13,85] respectively. It would be easier to retrieve the values for [x,y,w,h,conf,pred(class), pred(class) are next 80 probabilities for a specific object



# Conclusion

if we are using this to approach for a distributed architecture, this would be far easier if we use models that are supported by openvino as this would should require less post processing. If this is not possible, there will be a large learning curve to understand the model and how to parse the output from openvio.