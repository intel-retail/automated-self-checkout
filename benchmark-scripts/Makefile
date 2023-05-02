
build:
	docker build -t benchmark:dev -f Dockerfile.benchmark .

build-xpu:
	docker build --build-arg SERVER_GPU="true" -t benchmark:xpu -f Dockerfile.benchmark .

run:
	docker run -it --rm -v /var/run/docker.sock:/var/run/docker.sock -v `pwd`/results:/tmp/results -v /opt/intel/pcm/build/bin:/opt/intel/pcm/build/bin --net=host --privileged benchmark:dev /bin/bash