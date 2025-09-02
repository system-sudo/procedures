## Setup Loki as a service in Linux.

### 1: Create a new directory to store Loki binary and configuration file.
```sh
sudo mkdir /opt/loki
cd /opt/loki
```
### 2. Download archive from releases page of the Loki repository.

sudo wget -qO /opt/loki/loki.gz "https://github.com/grafana/loki/releases/download/v${LOKI_VERSION}/loki-linux-amd64.zip"
3. Extract binary file from archive.

sudo gunzip /opt/loki/loki.gz
4. Set execute permission for file.

sudo chmod a+x /opt/loki/loki
5. In /usr/local/bin directory we can create a symbolic link to the loki command.

sudo ln -s /opt/loki/loki /usr/local/bin/loki
Note: Now loki command is available for all users as a system-wide command.

Get Abdullah’s stories in your inbox
Join Medium for free to get updates from this writer.

Enter your email
Subscribe
6. Download configuration file for Loki.

sudo wget -qO /opt/loki/loki-local-config.yaml "https://raw.githubusercontent.com/grafana/loki/v${LOKI_VERSION}/cmd/loki/loki-local-config.yaml"
7. To verify installation, we can check Loki version.

loki -version
Step3: Setup Loki as service.
We can configure systemd for running Loki as a service

Create a systemd unit file.
sudo nano /etc/systemd/system/loki.service
2. Add the following content to the file.

[Unit]
Description=Loki log aggregation system
After=network.target

[Service]
ExecStart=/opt/loki/loki -config.file=/opt/loki/loki-local-config.yaml
Restart=always

[Install]
WantedBy=multi-user.target
3. Start Loki service.

sudo service loki start
sudo systemctl enable loki
4. Verify that Loki is running.

sudo service loki status
Success!!!!!
Press enter or click to view image in full size
