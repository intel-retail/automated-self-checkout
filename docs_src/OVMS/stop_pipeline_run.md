# Stop pipeline run
You can call `make clean-ovms` to stop the pipeline and all running containers for OVMS, hence the results directory log files will stop growing. Below is the table of make commands you can call to clean things up per your needs:

| Clean Containers Options                                     | Command                            |
| -------------------------------------------------------------| -----------------------------------|
| clean instance-segmentation container if any                 | <pre>make clean-segmentation</pre>      |
| clean grpc-go dev container if any                           | <pre>make clean-grpc-go</pre>      |
| clean all related containers launched by profile-launcher if any | <pre>make clean-profile-launcher</pre>  |
| clean ovms-server container                                 | <pre>make clean-ovms-server</pre> |
| clean ovms-server and all containers launched by profile-launcher          | <pre>make clean-ovms</pre>         |
| clean results/ folder                                        | <pre>make clean-results</pre>      |