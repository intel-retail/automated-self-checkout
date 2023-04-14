# How to get RealSense camera serial number

- run the built docker image in interactive mode, with root, and mount the host devices

`docker run --rm -u root -it --privileged sco-soc:2.0 bash`

- while in the container run `rs-enumerate-devices` to list metadata of all attached RealSense devices

```
/home/pipeline-zoo/workspace# rs-enumerate-devices
Device info: 
    Name                          :     Intel RealSense D435
    Serial Number                 :----->serial number<------
    Firmware Version              :     05.08.15.00
    Recommended Firmware Version  :     05.13.00.50
    Physical Port                 :     /sys/devices/pci0000:00/0000:00:14.0/usb2/2-3/2-3:1.0/video4linux/video0
    Debug Op Code                 :     15
    Advanced Mode                 :     YES
    Product Id                    :     0B07
    Camera Locked                 :     YES
    Product Line                  :     D400
    Asic Serial Number            :     <not the serial number>
    Firmware Update Id            :     <not the serial number>
```