package yolov5


const (
	outputSize           = 4
	confidence_threshold = .5
	boxiou_threshold     = .4
	iou_threshold        = 0.4
	classes              = 80
)

var (
	Input_shape = []int64{1, 416, 416, 3}
	// Anchors by region/output layer
	Anchors_52 = []float32{
		10.0,
		13.0,
		16.0,
		30.0,
		33.0,
		23.0,
	}

	Anchors_26 = []float32{
		30.0,
		61.0,
		62.0,
		45.0,
		59.0,
		119.0,
	}

	Anchors_13 = []float32{
		116.0,
		90.0,
		156.0,
		198.0,
		373.0,
		326.0,
	}

	Labels = []string{
		"person",
		"bicycle",
		"car",
		"motorbike",
		"aeroplane",
		"bus",
		"train",
		"truck",
		"boat",
		"traffic light",
		"fire hydrant",
		"stop sign",
		"parking meter",
		"bench",
		"bird",
		"cat",
		"dog",
		"horse",
		"sheep",
		"cow",
		"elephant",
		"bear",
		"zebra",
		"giraffe",
		"backpack",
		"umbrella",
		"handbag",
		"tie",
		"suitcase",
		"frisbee",
		"skis",
		"snowboard",
		"sports ball",
		"kite",
		"baseball bat",
		"baseball glove",
		"skateboard",
		"surfboard",
		"tennis racket",
		"bottle",
		"wine glass",
		"cup",
		"fork",
		"knife",
		"spoon",
		"bowl",
		"banana",
		"apple",
		"sandwich",
		"orange",
		"broccoli",
		"carrot",
		"hot dog",
		"pizza",
		"donut",
		"cake",
		"chair",
		"sofa",
		"pottedplant",
		"bed",
		"diningtable",
		"toilet",
		"tvmonitor",
		"laptop",
		"mouse",
		"remote",
		"keyboard",
		"cell phone",
		"microwave",
		"oven",
		"toaster",
		"sink",
		"refrigerator",
		"book",
		"clock",
		"vase",
		"scissors",
		"teddy bear",
		"hair drier",
		"toothbrush",
	}
)
