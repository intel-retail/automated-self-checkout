
build:
	docker build -t benchmark:dev -f Dockerfile.benchmark .

run:
	docker run -it --rm -v /usr:/usr -v /var/run/docker.sock:/var/run/docker.sock -v `pwd`/results:/tmp/results --net=host --privileged benchmark:xpu /bin/bash