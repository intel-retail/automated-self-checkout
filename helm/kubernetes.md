# pre-requisites

- Ubuntu 22.04
- [minikube](https://minikube.sigs.k8s.io/docs/start/)
- [kubectl](https://kubernetes.io/docs/tasks/tools/install-kubectl-linux/)
- [kompose](https://github.com/kubernetes/kompose?tab=readme-ov-file#binary-installation)


## Running your Kubernetes profile

```
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

helm repo add dls https://intel-retail.github.io/automated-self-checkout/
helm search repo dls
helm install dls dls/dls
kubectl exec --stdin --tty <container-id> -- /bin/bash

# Run multinode cluster

Minikube also offers the ability to start multiple nodes within the same cluster environment. This feature is particularly useful for developers who want to test the behavior of applications across multiple servers without needing multiple physical or virtual machines.

## Run minikube as multinode cluster

Example with 2 virtual nodes:

```
minikube start --nodes 2 -p multinode
```

Check the status of the cluster:

```
minikube status -p multinode
```

Output:

```bash
multinode
type: Control Plane
host: Running
kubelet: Running
apiserver: Running
kubeconfig: Configured

multinode-m02
type: Worker
host: Running
kubelet: Running
```

## Load the local docker images

For a multinode setup, we need to load the local docker images to all nodes.

```
minikube image load dlstreamer:deploy
```

## Run all pods

```
kubectl apply -f kubernetes
```

## Check the deployment

```
kubectl get pods -o wide
```

Output: 

| NAME                               | READY | STATUS  | RESTARTS    | AGE | IP        | NODE          
|------------------------------------|-------|---------|-------------|-----|-----------|---------------
| camera-simulator-c499bdd5c-m4mz4   | 1/1   | Running | 0           | 34s | 10.244.2.2| multinode-m02 
| camera-simulator0-766bd6f7d4-p5vz8 | 1/1   | Running | 2 (33s ago) | 34s | 10.244.2.3| multinode-m02 
| dlstreamer-84b565f55d-59rjm        | 1/1   | Running | 2 (28s ago) | 34s | 10.244.2.4| multinode-m02 


## Scale dlstreamer deployment to 5 replicas

```
kubectl scale deployment dlstreamer --replicas=5
```

Verify that all replicas are running and notice how some of the replicas are running on **multinode-m02** and other on **multinode** nodes.

```
kubectl get pods -o wide
```

Output:

```
| NAME                               | READY | STATUS  | RESTARTS        | AGE   | IP         | NODE          
|------------------------------------|-------|---------|-----------------|-------|------------|---------------
| camera-simulator-c499bdd5c-m4mz4   | 1/1   | Running | 0               | 5m28s | 10.244.2.2 | multinode-m02 
| camera-simulator0-766bd6f7d4-p5vz8 | 1/1   | Running | 2 (5m27s ago)   | 5m28s | 10.244.2.3 | multinode-m02 
| dlstreamer-84b565f55d-59rjm        | 1/1   | Running | 2 (5m22s ago)   | 5m28s | 10.244.2.4 | multinode-m02 
| dlstreamer-84b565f55d-78zdx        | 1/1   | Running | 0               | 104s  | 10.244.2.5 | multinode-m02 
| dlstreamer-84b565f55d-7pn8z        | 1/1   | Running | 0               | 88s   | 10.244.0.6 | multinode     
| dlstreamer-84b565f55d-dnqbk        | 1/1   | Running | 0               | 88s   | 10.244.2.6 | multinode-m02 
| dlstreamer-84b565f55d-z69ch        | 1/1   | Running | 0               | 104s  | 10.244.0.5 | multinode     

```

## Run minikube dashboard

If you need a better visualizer, you can use the built in dashboard from minikube:

```
minikube dashboard -p multinode
```

## Stop cluster

```
minikube stop -p multinode
```

## Troubleshooting

If you get the **ErrImagePull** message while deploying the pods, it means the local docker images can't be accessed by the cluster nodes.
You can restart the cluster by running:

```
minikube stop -p multinode
minikube start --nodes 2 -p multinode
```

You can try these commands to load the images instead of the **minikube load**

```
minikube cache add dlstreamer:deploy
```

Make sure you built the images before doing the loading.
