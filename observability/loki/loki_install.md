## Setup Loki as a service in Linux.
### Always refer Official Documentation:  
https://grafana.com/docs/loki/latest/setup/install/local/
### 1: Create a new directory to store Loki binary and configuration file.
```sh
sudo mkdir /opt/loki
cd /opt/loki
```
### 2. Download archive from releases page of the Loki repository.
#### RUN below cmd to automatically get the latest version:
```sh
sudo curl -s https://api.github.com/repos/grafana/loki/releases/latest | \
grep browser_download_url | \
grep loki-linux-amd64.zip | \
cut -d '"' -f 4 | \
sudo wget -qi -
```
#### or Get the specific version of Loki:  
replace version no.
```sh
curl -O -L "https://github.com/grafana/loki/releases/download/v3.4.2/loki-linux-amd64.zip"
```
#### 3. Extract binary file from archive.
```sh
sudo unzip loki-linux-amd64.zip
```
#### 4: Make Loki Executable and Move to System Path
```sh
chmod +x loki-linux-amd64
sudo mv loki-linux-amd64 /usr/local/bin/loki
sudo chmod +x /usr/local/bin/loki
```
#### 5. Download configuration file for Loki.
Use the Git references that match your downloaded Loki version to get the correct configuration file.  
For example, if you are using Loki version 3.4.1,  
you need to use the https://raw.githubusercontent.com/grafana/loki/v3.4.1/cmd/loki/loki-local-config.yaml URL to download the configuration file.  
This main option get the latest:
```sh
wget https://raw.githubusercontent.com/grafana/loki/main/cmd/loki/loki-local-config.yaml
```
#### 6. To verify installation, we can check Loki version.
```sh
loki -version
```
Check Loki’s metrics endpoint:  
http://ip:3100/metrics
#### 7: Setup Loki as service.
Create a systemd unit file.
```sh
sudo nano /etc/systemd/system/loki.service
```
Add the following content to the file.
```sh
[Unit]
Description=Loki Log Aggregation System
After=network.target

[Service]
User=root
ExecStart=/usr/local/bin/loki --config.file=/root/loki-local-config.yaml
Restart=always
LimitNOFILE=65536

[Install]
WantedBy=multi-user.target
```
#### 8. Enable and Start Loki.
```sh
sudo systemctl daemon-reload
sudo systemctl enable loki
sudo systemctl start loki
```
#### 9.Verify that Loki is running.
```sh
sudo systemctl restart loki
```
```sh
sudo systemctl status loki
```
### 10. Check Loki logs (for any Errors):
Loki logs errors before crashing:
```sh
sudo journalctl -u loki.service --no-pager | tail -n 50
```

#### Sources:
https://awstip.com/setting-up-loki-for-log-aggregation-a-complete-guide-b639c4bf56e5
