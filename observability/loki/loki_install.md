## Setup Loki as a service in Linux.
### Recommended to follow Official Documentation:
```
https://grafana.com/docs/loki/latest/setup/install/local/
```
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
sudo chmod +x loki-linux-amd64
sudo mv loki-linux-amd64 /usr/local/bin/loki
sudo chmod +x /usr/local/bin/loki
```
#### 5. Download configuration file for Loki.
Use the Git references that match your downloaded Loki version to get the correct configuration file.  
For example, if you are using Loki version 3.4.1,  
you need to use the https://raw.githubusercontent.com/grafana/loki/v3.4.1/cmd/loki/loki-local-config.yaml URL to download the configuration file.  

#### we can keep Config file at any place but just mention its location in service file: for now its in:
```
cd /opt/loki
```
Create a File for Loki Config:
```sh
sudo nano /opt/loki/loki-local-config.yaml
```
##### This is modified Loki Config:
paste the following
```sh
auth_enabled: false

server:
  http_listen_port: 3100
  grpc_listen_port: 9096
  log_level: debug
  grpc_server_max_concurrent_streams: 1000

common:
  instance_addr: 127.0.0.1
  path_prefix: /tmp/loki
  storage:
    filesystem:
      chunks_directory: /tmp/loki/chunks
      rules_directory: /tmp/loki/rules
  replication_factor: 1
  ring:
    kvstore:
      store: memberlist

memberlist:
  join_members:
    - 127.0.0.1

query_range:
  results_cache:
    cache:
      embedded_cache:
        enabled: true
        max_size_mb: 100

limits_config:
  metric_aggregation_enabled: true
  enable_multi_variant_queries: true
  allow_structured_metadata: false
  retention_period: 336h  # 14 days in hours

schema_config:
  configs:
    - from: 2020-10-24
      store: tsdb
      object_store: filesystem
      schema: v13
      index:
        prefix: index_
        period: 24h

ingester:
  chunk_idle_period: 5m
  chunk_retain_period: 30s
  max_chunk_age: 1h

compactor:
  working_directory: /tmp/loki/compactor
  retention_enabled: true
  delete_request_store: filesystem
  #shared_store: filesystem

pattern_ingester:
  enabled: true
  metric_aggregation:
    loki_address: localhost:3100

ruler:
  alertmanager_url: http://localhost:9093

frontend:
  encoding: protobuf

#analytics:
#reporting_enabled: false
```
OR  
This main option get the latest official Loki Config:
```sh
wget https://raw.githubusercontent.com/grafana/loki/main/cmd/loki/loki-local-config.yaml
```

#### 6. To verify installation, we can check Loki version.
```sh
loki -version
```
#### 7. Create a dedicated Loki user (for security)
It’s best practice to run Loki under a non-root user.
```sh
sudo useradd --no-create-home --shell /usr/sbin/nologin loki
```
Give ownership of Loki’s working directory:
```sh
sudo chown -R loki:loki /opt/loki
sudo mkdir -p /tmp/loki
sudo chown -R loki:loki /tmp/loki
```
#### 8: Setup Loki as service.
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
Type=simple
User=loki
Group=loki
ExecStart=/usr/local/bin/loki --config.file=/opt/loki/loki-local-config.yaml
Restart=on-failure
RestartSec=5
LimitNOFILE=65536
TimeoutStopSec=20

[Install]
WantedBy=multi-user.target
```
#### 9. Enable and Start Loki.
```sh
sudo systemctl daemon-reload
sudo systemctl enable loki
sudo systemctl start loki
```
#### 10.Verify that Loki is running.
```sh
sudo systemctl restart loki
```
```sh
sudo systemctl status loki
```
Check Loki’s metrics endpoint:  
```sh
http://ip:3100/metrics
```
### 11. Check Loki logs (for any Errors):
Loki logs errors before crashing:
```sh
sudo journalctl -u loki.service --no-pager | tail -n 50
```

#### Sources:
https://awstip.com/setting-up-loki-for-log-aggregation-a-complete-guide-b639c4bf56e5

For Webinar from Grafana on Loki
https://grafana.com/go/webinar/getting-started-with-logging-and-grafana-loki/?pg=webinar-scaling-and-securing-your-logs-with-grafana-loki&plcmt=related-sidebar-2
