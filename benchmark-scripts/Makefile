
build-all: build-benchmark build-xpu build-igt

build-benchmark:
	echo "Building benchmark container HTTPS_PROXY=${HTTPS_PROXY} HTTP_PROXY=${HTTP_PROXY}"
	docker build --build-arg HTTPS_PROXY=${HTTPS_PROXY} --build-arg HTTP_PROXY=${HTTP_PROXY} -t benchmark:dev -f Dockerfile.benchmark .

build-xpu:
	echo "Building xpu HTTPS_PROXY=${HTTPS_PROXY} HTTP_PROXY=${HTTP_PROXY}"
	docker build --build-arg HTTPS_PROXY=${HTTPS_PROXY} --build-arg HTTP_PROXY=${HTTP_PROXY} -t benchmark:xpu -f Dockerfile.xpu .

build-igt:
	echo "Building igt HTTPS_PROXY=${HTTPS_PROXY} HTTP_PROXY=${HTTP_PROXY}"
	docker build --build-arg HTTPS_PROXY=${HTTPS_PROXY} --build-arg HTTP_PROXY=${HTTP_PROXY} -t benchmark:igt -f Dockerfile.igt .

run:
	docker run -it --rm -v /var/run/docker.sock:/var/run/docker.sock -v `pwd`/results:/tmp/results --net=host --privileged benchmark:dev /bin/bash

consolidate:
	docker run -itd -v `pwd`/$(ROOT_DIRECTORY):/$(ROOT_DIRECTORY) -e ROOT_DIRECTORY=$(ROOT_DIRECTORY)--net=host --privileged benchmark:dev /bin/bash -c "python3 consolidate_multiple_run_of_metrics.py --root_directory $(ROOT_DIRECTORY)/ --output $(ROOT_DIRECTORY)/summary.csv"