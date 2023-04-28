
build:
	docker build -t benchmark:dev -f Dockerfile.benchmark .

build-xpu:
	docker build --build-arg SERVER_GPU="true" -t benchmark:xpu -f Dockerfile.benchmark .

run:
	docker run -it --rm benchmark:dev /bin/bash