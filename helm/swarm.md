# Deploy using docker swarm

This document guides you to deploy a cluster using docker swarm with physical nodes.

## Pre-requisite 

- Ubuntu 22.04
- [Docker](https://docs.docker.com/engine/install/ubuntu/#install-using-the-repository)

## Build docker images on all nodes

Ensure that **dlstreamer:deploy** docker images are built on every node.
You can transfer the docker images to the other nodes or you can clone and run this command on every node to ensure the images are available.

```
make build-all
```

## Setting up Docker swarm

Start swarm mode

```
docker swarm init
```

### Join other worker nodes

For now, only the manager node will be available, if you want to join other nodes, execute the following command:

```
docker swarm join-token worker
```

This command will output something like the following, including a docker swarm join command with the token:

```
To add a worker to this swarm, run the following command:

    docker swarm join --token SWMTKN-1-49nj1cmql0... 192.168.99.100:2377
```

On the new machine that you want to add as a worker node, run the docker swarm join command that you copied from the manager node. It should look something like this:


```
docker swarm join --token SWMTKN-1-49nj1cmql0... 192.168.99.100:2377
```

Make sure to replace the token and IP address with the actual values you got from your manager node. This command will connect the worker node to the Docker Swarm managed by the manager node.

### Verify the nodes

To confirm that the new node has successfully joined the swarm, go back to your manager node and run:

```
docker node ls
```

| ID              | HOSTNAME        | STATUS | AVAILABILITY | MANAGER STATUS | ENGINE VERSION |
|-----------------|-----------------|--------|--------------|----------------|----------------|
| 1216415 *       | manager         | Ready  | Active       | Leader         | 23.0.3         |
| 1231321         | worker1         | Ready  | Active       |                | 24.0.7         |

## Deploy the automated self checkout solution

With your Swarm initialized and the Automated self checkout compose file , deploy the stack using the following command:

```
docker stack deploy -c docker-compose.yml checkout
```

### Verify the deployment

Check the status of your stack deployment using the following command:

```
docker stack services checkout
```

Output:

| ID             | NAME                         | MODE        | REPLICAS | IMAGE                              | PORTS              |
|----------------|------------------------------|-------------|----------|------------------------------------|--------------------|
| sadfdsfdsfdd   | checkout_camera-simulator    | replicated  | 1/1      | aler9/rtsp-simple-server:latest    | *:8554->8554/tcp   |
| sdfsdfsdfdsf   | checkout_camera-simulator0   | replicated  | 1/1      | jrottenberg/ffmpeg:4.1-alpine      |                    |
| dsfewfdesfdf   | checkout_dlstreamer          | replicated  | 1/1      | dlstreamer:deploy                  |                    |

### Scale dlstreamer container 

This command allows you to adjust the number of replicas (instances) of a service to the desired count.

```
docker service scale checkout_dlstreamer=5
```

### Verify all replicas

To verify that all replicas are running and identify the nodes they are running on, use the following command:

```
docker service ps checkout_dlstreamer
```

Output:

| ID         | NAME                      | IMAGE            | NODE            | DESIRED STATE | CURRENT STATE            | ERROR | PORTS |
|------------|---------------------------|------------------|-----------------|---------------|--------------------------|-------|-------|
| 7u9vyb798sv0 | checkout_dlstreamer.1     | dlstreamer:deploy | worker1 | Running       | Running 6 minutes ago    |       |       |
| sekrd09ej7p3 | \_ checkout_dlstreamer.1 | dlstreamer:deploy | worker1 | Shutdown      | Complete 6 minutes ago   |       |       |
| 49bt82k5tc12 | checkout_dlstreamer.2     | dlstreamer:deploy | manager  | Running       | Running 34 seconds ago   |       |       |
| pkstj7rqqhnv | checkout_dlstreamer.3     | dlstreamer:deploy | worker1 | Running       | Running 33 seconds ago   |       |       |
| 28nkyvpo4e5k | checkout_dlstreamer.4     | dlstreamer:deploy | manager  | Running       | Running 34 seconds ago   |       |       |
| 721pnp6989pr | checkout_dlstreamer.5     | dlstreamer:deploy | worker1 | Running       | Running 34 seconds ago   |       |       |


## Stop the swarm

```
docker stack rm checkout
```