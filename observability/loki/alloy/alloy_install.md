## Install Grafana Alloy on Linux
Follow Offcial Documentaion:
```
https://grafana.com/docs/alloy/latest/set-up/install/linux/
```

### You can install Alloy as a systemd service on Linux.

#### Install GPG in your Linux Virtual Machine: (If GPG is not installed by default)
```sh
sudo apt install gpg
```

### STEP 1: To install Alloy on Linux:

#### 1. Import the GPG key and add the Grafana package repository.
```sh
sudo mkdir -p /etc/apt/keyrings/
wget -q -O - https://apt.grafana.com/gpg.key | gpg --dearmor | sudo tee /etc/apt/keyrings/grafana.gpg > /dev/null
echo "deb [signed-by=/etc/apt/keyrings/grafana.gpg] https://apt.grafana.com stable main" | sudo tee /etc/apt/sources.list.d/grafana.list
```
#### 2. Update the repositories.
```sh
sudo apt-get update
```
#### 3. Install Alloy.
```sh
sudo apt-get install alloy
```

### STEP 2: Run Grafana Alloy on Linux:
Follow Offcial Documentaion:
```
https://grafana.com/docs/alloy/latest/set-up/run/linux/
```
#### To start Alloy, run the following command.
```sh
sudo systemctl start alloy
```
#### To verify that the service is running, run the following command.
```sh
sudo systemctl status alloy
```
#### Configure Alloy to start at boot.
```sh
sudo systemctl enable alloy.service
```
#### Restart Alloy
```sh
sudo systemctl restart alloy
```
#### Stop Alloy
```sh
sudo systemctl stop alloy
```
#### To view Alloy log files for any Errors:
```sh
sudo journalctl -u alloy.service -f
```

### STEP 3: Configure Grafana Alloy on Linux
Follow Offcial Documentaion:
```
https://grafana.com/docs/alloy/latest/configure/linux/
```
#### Edit the default configuration file To configure Alloy:
```sh
sudo vi /etc/default/alloy.
```
#### To change the configuration file used by the service, perform the following steps:
default configuration file at /etc/alloy/config.alloy.
change it to 
```sh
CONFIG_FILE="/opt/alloy"
```
#### Expose the UI to other machines

#### Add the following command line argument to CUSTOM_ARGS To listen on all interfaces: with 0.0.0.0.
```sh
CUSTOM_ARGS="--server.http.listen-addr=0.0.0.0:12345"
```
#### reload the configuration file:
```sh
sudo systemctl reload alloy
```
Restart the Alloy service:
```sh
sudo systemctl restart alloy
```

### STEP 4: Alloy needs permission to read logs:
#### Option 1. Give permission to read only that log File
check who has permission for the specific log file:
```
sudo ls -l
```
Add alloy to particular owner Group(eg.ubuntu) and Adjust Permissions
```
sudo usermod -aG ubuntu alloy
```
To verify that the alloy user has been added to the ubuntu(particular) group:
```sh
groups alloy
```
or
```sh
id alloy
```
Restart the Alloy service:
```sh
sudo systemctl restart alloy
```

#### Option 2. Change alloy service to run as root (Not Reccomended)
```sh
cd /usr/lib/systemd/system
sudo vi alloy.service
```
Change User to root

### STEP 5: To uninstall Alloy on Linux:

#### 1. Stop the systemd service for Alloy.
```sh
sudo systemctl stop alloy
```
#### 2. Uninstall Alloy.
```sh
sudo apt-get remove alloy
```
#### 3. Optional: Remove the Grafana repository.
```sh
sudo rm -i /etc/apt/sources.list.d/grafana.list
```
