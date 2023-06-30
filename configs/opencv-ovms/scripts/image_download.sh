#!/bin/bash

if [ ! -f configs/opencv-ovms/images/sample-bottle.jpg ]; then
	echo "Downloading sample image"
	curl "https://images.pexels.com/photos/4389678/pexels-photo-4389678.jpeg?cs=srgb&dl=pexels-karolina-grabowska-4389678.jpg&fm=jpg&w=1280&h=1920&_gl=1*1lus06a*_ga*NjU2OTUyNjU3LjE2Njc1OTYyNjI.*_ga_8JE65Q40S6*MTY3OTYxNTI3NC4xNy4xLjE2Nzk2MTY4NjkuMC4wLjA." --output configs/opencv-ovms/images/sample-bottle.jpg
fi

