## ✅ Step-by-Step: Run mysqld_exporter as a Service

### 1️⃣ Download mysqld_exporter Binary
#### 📦 Get the latest version from Prometheus GitHub:
https://prometheus.io/download/#mysqld_exporter
```sh
sudo curl -LO https://github.com/prometheus/mysqld_exporter/releases/download/v0.17.2/mysqld_exporter-0.17.2.linux-amd64.tar.gz
```
#### unzip using tar
```sh
sudo tar -xzf mysqld_exporter-0.17.2.linux-amd64.tar.gz
```
#### rename the mysqld_exporter-0.17.2.linux-amd64 to a shorter name - mysqld_exporter
```sh
sudo mv mysqld_exporter-0.17.2.linux-amd64 mysqld_exporter
```
### 2️⃣ Create a System User

```sh
sudo useradd -rs /bin/false node_exporter
```
### 3️⃣ Move Binary to /usr/local/bin
```sh
sudo mv node_exporter/node_exporter /usr/local/bin/
sudo chown node_exporter:node_exporter /usr/local/bin/node_exporter
```
### 4️⃣ Create a Systemd Service File
#### Create the service unit:

```sh
sudo vim /etc/systemd/system/node_exporter.service
```
#### Paste the following:

```sh
[Unit]
Description=Node Exporter
After=network.target

[Service]
User=node_exporter
Group=node_exporter
Type=simple
ExecStart=/usr/local/bin/node_exporter
Restart=on-failure

[Install]
WantedBy=default.target
```
Save and exit (:wq in Vim).
### 5️⃣ Start and Enable Node Exporter
```sh
sudo systemctl daemon-reload
sudo systemctl enable node_exporter
sudo systemctl start node_exporter
```
#### Check status:

```sh
sudo systemctl status node_exporter
```
### 6️⃣ Verify Node Exporter is Running
#### Open in browser:

```sh
http://<server-ip>:9100/metrics
```
### 7️⃣ Add to Prometheus Targets
Edit your Prometheus config (prometheus.yml):
```sh
sudo vi /etc/prometheus/prometheus.yml
```

```sh
  - job_name: 'node-exporter' # Name Identifier
    static_configs:
      - targets: ['<server-ip>:9100']
```
Then restart Prometheus:

```sh
sudo systemctl restart prometheus
```
