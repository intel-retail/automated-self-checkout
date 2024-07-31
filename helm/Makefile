# Copyright © 2024 Intel Corporation. All rights reserved.
# SPDX-License-Identifier: Apache-2.0

.PHONY: build build-all build-minikube run-minikube-demo stop-minikube-demo helm-convert install-helm uninstall-helm

build:
	docker build --build-arg HTTPS_PROXY=${HTTPS_PROXY} --build-arg HTTP_PROXY=${HTTP_PROXY} -t dlstreamer:deploy -f Dockerfile ..

build-minikube: build 
	minikube start
	minikube image build -t dlstreamer:deploy -f helm/Dockerfile ..

run-minikube-demo: build-minikube
	kompose -f docker-compose.yml convert -o kubernetes/ && \
	kubectl apply -f kubernetes
	
stop-minikube-demo:
	kubectl delete -f kubernetes
	minikube stop

helm-convert:
	kompose -f docker-compose.yml convert -o kubernetes -c

install-helm:
	helm install -f kubernetes/Chart.yaml dls kubernetes

uninstall-helm:
	helm uninstall dls