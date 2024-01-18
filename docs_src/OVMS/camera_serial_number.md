# Get Serial Number of Intel® RealSense™ Camera

Do the following to get the serial number of an Intel® RealSense™ Camera:

1. Build the RealSense version of dlstreamer Docker image if not done yet:

   ```bash
   make build-dlstreamer-realsense
   ```

2. Plug in your Intel® RealSense™ Camera into the system;

3. Use the makefile target `get-realsense-serial-num` to get the serial number of your Intel® RealSense™ Camera:

   ```bash
   make get-realsense-serial-num
   ```

You should see a serial number printed out. If you do not see the expected results, check if the Intel® RealSense™ Camera is plugged in.
