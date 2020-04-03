### <span style="font-family: times, serif; font-size:16pt; font-style:italic;">  OpsWorks Logs Collector

<span style="font-family: calibri, Garamond, 'Comic Sans MS' ;"> Script created to collect log files related to OpsWorks and the OS to help troubleshooting issues with this service.</span>

* Run this script as root user:
```
curl -O https://raw.githubusercontent.com/mstelles/ow-logs-collector/master/ow-logs-collector.sh
sudo sh ow-logs-collector.sh
```
* After the execution, a file named "ow-logs-collector-\<instance ID\>.tar.bz2" will be created at the /opt/ow-logs-collector/ directory.

* Download the file with any SCP tool you like.

