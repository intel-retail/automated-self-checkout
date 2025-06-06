## Deep Learning Streamer Pipeline Server (EVAM)

1. First clone the repository and run the following command at the root level.

2. build and run pipelines

```bash
make run-pipeline-server
```

3. Validate docker containers are running

```bash
docker ps --format 'table{{.Names}}\t{{.Image}}\t{{.Status}}'
```

result:

| NAMES                                    | IMAGE                                                      | STATUS                                 |
|------------------------------------------|-------------------------------------------------------------|----------------------------------------|
| camera-simulator0                        | jrottenberg/ffmpeg:4.1-alpine                              | Up 5 seconds                           |
| camera-simulator1                        | jrottenberg/ffmpeg:4.1-alpine                              | Up 5 seconds                           |
| camera-simulator2                        | jrottenberg/ffmpeg:4.1-alpine                              | Up 5 seconds                           |
| edge-video-analytics-microservice        | intel/edge-video-analytics-microservice:2.3.0              | Up 5 seconds                           |
| multimodal-data-visualization            | intel/multimodal-data-visualization:5.0.0                  | Up 5 seconds (health: starting)        |
| multimodal-data-visualization-streaming  | intel/multimodal-data-visualization-streaming:5.0.0        | Up 5 seconds (health: starting)        |
| mqtt-broker                              | eclipse-mosquitto:2.0.18                                   | Up 5 seconds                           |
| pipeline-init                            | postman/newman                                             | Up 5 seconds                           |
| webrtc-signaling-server                  | intel/simple-signaling-server:5.0.0                        | Up 5 seconds (health: starting)        |
| camera-simulator                         | aler9/rtsp-simple-server                                   | Up 5 seconds                           |


3. Open your browser and go to: [http://127.0.0.1:3000](http://127.0.0.1:3000)  
Log in with the following credentials:  
   - **Username:** `root`  
   - **Password:** `evam123`  

Once logged in, navigate to the **default dashboard** from the homepage.

5. Validate MQTT inference output

```bash
mosquitto_sub -v -h localhost -p 1883 -t 'AnalyticsData0'
mosquitto_sub -v -h localhost -p 1883 -t 'AnalyticsData1'
mosquitto_sub -v -h localhost -p 1883 -t 'AnalyticsData2'
```

result per sub command:

```
AnalyticsData0 {"objects":[{"detection":{"bounding_box":{"x_max":0.3163176067521043,"x_min":0.20249048400491532,"y_max":0.7995593662281202,"y_min":0.12237883070032396},"confidence":0.868196964263916,"label":"bottle","label_id":39},"h":731,"region_id":6199,"roi_type":"bottle","w":219,"x":389,"y":132},{"detection":{"bounding_box":{"x_max":0.7833052431819754,"x_min":0.6710088227893136,"y_max":0.810283140877349,"y_min":0.1329853767638305},"confidence":0.8499506711959839,"label":"bottle","label_id":39},"h":731,"region_id":6200,"roi_type":"bottle","w":216,"x":1288,"y":144}],"resolution":{"height":1080,"width":1920},"tags":{},"timestamp":67297301635}
AnalyticsData0 {"objects":[{"detection":{"bounding_box":{"x_max":0.3163306922646063,"x_min":0.20249845268772138,"y_max":0.7984013488063937,"y_min":0.12254781445953},"confidence":0.8666459321975708,"label":"bottle","label_id":39},"h":730,"region_id":6201,"roi_type":"bottle","w":219,"x":389,"y":132},{"detection":{"bounding_box":{"x_max":0.7850104587729607,"x_min":0.6687324296210857,"y_max":0.7971464600783804,"y_min":0.13681757042794374},"confidence":0.8462932109832764,"label":"bottle","label_id":39},"h":713,"region_id":6202,"roi_type":"bottle","w":223,"x":1284,"y":148}],"resolution":{"height":1080,"width":1920},"tags":{},"timestamp":67330637174}
```

6. Run the status command script

```bash
./src/pipeline-server/status.sh 
```

```
--------------------- Pipeline Status ---------------------
----------------8080----------------
[
  {
    "avg_fps": 11.862402507697258,
    "avg_pipeline_latency": 0.5888091060475129,
    "elapsed_time": 268.07383918762207,
    "id": "95204aba458211efa9080242ac180006",
    "message": "",
    "start_time": 1721361269.6349292,
    "state": "RUNNING"
  }
]
----------------8081----------------
[
  {
    "avg_fps": 11.481329713987789,
    "avg_pipeline_latency": 0.6092195660469542,
    "elapsed_time": 262.33892583847046,
    "id": "98233952458211efb5090242ac180007",
    "message": "",
    "start_time": 1721361275.3886085,
    "state": "RUNNING"
  }
]
----------------8082----------------
[
  {
    "avg_fps": 11.374176117139063,
    "avg_pipeline_latency": 0.6153032569996222,
    "elapsed_time": 256.985634803772,
    "id": "9b2385a8458211efa46f0242ac180005",
    "message": "",
    "start_time": 1721361280.7602823,
    "state": "RUNNING"
  }
]
```

7. Stop services

```bash
make down-pipeline-server
```
