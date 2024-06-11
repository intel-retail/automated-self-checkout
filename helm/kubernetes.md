# pre-requisites

- Ubuntu 22.04
- [minikube](https://minikube.sigs.k8s.io/docs/start/)
- [kubectl](https://kubernetes.io/docs/tasks/tools/install-kubectl-linux/)
- [kompose](https://github.com/kubernetes/kompose?tab=readme-ov-file#binary-installation)


## Running your Kubernetes profile

```
minikube start

make build-minikube

make run-minikube-demo
```

## Verify pipeline

```
kubectl get pods
```
Output
```
NAME                                READY   STATUS    RESTARTS      AGE
camera-simulator-67b747df75-jh4sp   1/1     Running   0             24s
camera-simulator0-b7db8996f-bj8vw   1/1     Running   2 (17s ago)   24s
dlstreamer-5c684668dc-dlgw2         1/1     Running   1 (8s ago)    24s
```

```
kubectl logs dlstreamer-5c684668dc-dlgw2
```

```
...
0:00:53.524157446     9 0x55ca298c2400 TRACE             GST_TRACER :0:: latency_tracer_pipeline_interval, interval=(double)133.312186, avg=(double)1950.824074, min=(double)1947.401942, max=(double)1953.621574, latency=(double)33.328046, fps=(double)30.004759;
0:00:53.524169258     9 0x55ca298c2400 TRACE             GST_TRACER :0:: latency_tracer_pipeline, frame_latency=(double)1948.651205, avg=(double)1360.726029, min=(double)195.100065, max=(double)3663.061196, latency=(double)33.246986, fps=(double)30.077914, frame_num=(uint)1425;
```

## Stop Kubernetes profile

```
make stop-minikube-demo
```

## Converting your Docker Compose file

``` 
kompose -f docker-compose.yml convert -o kubernetes/
```

## Useful helm commands

helm package charts/ -u -d .deploy
helm package charts/
helm repo index .
helm repo index --url https://github.com/brian-intel/retail-use-cases .

helm repo add dls https://brian-intel.github.io/retail-use-cases/
helm search repo dls
helm install dls dls/dls
kubectl exec --stdin --tty <container-id> -- /bin/bash