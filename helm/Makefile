# Copyright © 2023 Intel Corporation. All rights reserved.
# SPDX-License-Identifier: Apache-2.0

.PHONY: build build-cam-sim build-minikube run-minikube-demo stop-minikube-demo helm-convert install-helm uninstall-helm

build:
	docker build --build-arg HTTPS_PROXY=${HTTPS_PROXY} --build-arg HTTP_PROXY=${HTTP_PROXY} -t dlstreamer:dev -f Dockerfile ..

build-cam-sim:
	docker build --build-arg HTTPS_PROXY=${HTTPS_PROXY} --build-arg HTTP_PROXY=${HTTP_PROXY} -t cam-sim:dev -f Dockerfile.cam-sim .

build-minikube: build build-cam-sim
	minikube start
	minikube image build -t dlstreamer:dev -f helm/Dockerfile ..
	minikube image build -t cam-sim:dev -f Dockerfile.cam-sim .

run-minikube-demo: build-minikube
	kompose -f docker-compose.yml convert -o kubernetes/ && \
	kubectl apply -f kubernetes
	
stop-minikube-demo:
	kubectl delete -f kubernetes

helm-convert:
	kompose -f docker-compose.yml convert -o kubernetes -c

install-helm:
	helm install -f kubernetes/Chart.yaml dls kubernetes

uninstall-helm:
	helm uninstall dls