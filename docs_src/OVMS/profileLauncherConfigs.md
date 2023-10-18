# Profile Configuration

For the profile launcher, each profile has its own configuration for different pipelines.  The configuration of each profile is done through an yaml configuration file, configuration.yaml.  One example of configuration.yaml is [shown here for classification](https://github.com/intel-retail/automated-self-checkout/blob/main/configs/opencv-ovms/cmd_client/res/classification/configuration.yaml):

```yaml
OvmsSingleContainer: false
OvmsServer:
  ServerDockerScript: start_ovms_server.sh
  ServerDockerImage: openvino/model_server:2023.1-gpu
  ServerContainerName: ovms-server
  ServerConfig: "/models/config.json"
  StartupMessage: Starting OVMS server
  InitWaitTime: 10s
  EnvironmentVariableFiles:
    - ovms_server.env
  # StartUpPolicy:
  # when there is an error on launching ovms server startup, choose one of these values for the behavior of profile-launcher: 
  #   remove-and-restart: it will remove the existing container with the same container name if any and then restart the container
  #   exit: it will exit the profile-launcher and 
  #   ignore: it will ignore the error and continue (this is the default value if not given or none of the above)
  StartUpPolicy: ignore    
OvmsClient:
  DockerLauncher:
    Script: docker-launcher.sh
    DockerImage: python-demo:dev
    ContainerName: classification
    Volumes:
      - "$RUN_PATH/results:/tmp/results"
      - ~/.Xauthority:/home/dlstreamer/.Xauthority
      - /tmp/.X11-unix
  PipelineScript: ./classification/python/entrypoint.sh
  PipelineInputArgs: "" # space delimited like we run the script in command and take those input arguments
  EnvironmentVariableFiles:
    - classification.env
```

The description of each configuration element is explained below:

---

| Configuration Element                   | Description                     |
| ---------------------------------------------- | ------------------------------------------ |
| OvmsSingleContainer     | This boolean flag indicates whether this profile is running as a single OpenVino Model Server (OVMS) container or not, e.g. the C-API pipeline use case will use this as `true`. <br>It can indicate the distributed architecture of OVMS client-server when this flag is false. </br>  |
| OvmsServer                           | This is configuration section for OpenVino Model Server in the case of client-server architecture. |
| OvmsServer/ServerDockerScript        | The infra-structure shell script to start an instance of OVMS server.  |
| OvmsServer/ServerDockerImage         | The Docker image tag name for OpenVino Model Server.  |
| OvmsServer/ServerContainerName       | The Docker container base name for OpenVino Model Server.  |
| OvmsServer/ServerConfig              | The model config.json file name path for OpenVino Model Server.  |
| OvmsServer/StartupMessage            | The starting message shown in the console or log when OpenVino Model Server instance is launched. |
| OvmsServer/InitWaitTime              | The waiting time duration (like 5s, 5m, .. etc) after OpenVino Model Server is launched to allow some settling time before launching the pipeline from the client. |
| OvmsServer/EnvironmentVariableFiles  | The list of environment variable files applied for starting OpenVino Model Server Docker instance. |
| OvmsServer/StartUpPolicy             | This configuration controls the behavior of OpenVino Model Server Docker instance when there is error occurred during launching. <br>Use one of these values:</br>  `remove-and-restart`: it will remove the existing container with the same container name if any and then restart the container <br> `exit`: it will exit the profile-launcher <br>`ignore`: it will ignore the error and continue (this is the default value if not given or none of the above). </br> |
| OvmsClient                           | This is configuration section for the OVMS client running pipelines in the case of client-server architecture. <br>The C-API pipeline use case should also use this section to configure. |
| OvmsClient/DockerLauncher            | This is configuration section for the generic Docker launcher to run pipelines for a given profile. |
| OvmsClient/DockerLauncher/Script        | The generic Docker launcher script file name. |
| OvmsClient/DockerLauncher/DockerImage   | The Docker image tag name for the pipeline profile. |
| OvmsClient/DockerLauncher/ContainerName | The Docker container base name for the running pipeline profile. |
| OvmsClient/DockerLauncher/Volumes       | The Docker container volume mounts for the running pipeline profile. |
| OvmsClient/PipelineScript               | The file name path for the the pipeline profile to launch. The file path here is in the perspective of the running container. i.e. the path inside the running container. |
| OvmsClient/PipelineInputArgs            | Any input arguments or parameters for the above pipeline script to take. Like any command line argument, they are space-delimited if multiple arguments. |
| OvmsClient/EnvironmentVariableFiles     | The list of environment variable files applied for the running pipeline profile Docker instance. |

---
