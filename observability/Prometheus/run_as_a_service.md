## 🛠️ Step-by-Step Guide to Create Prometheus as a Service  
```sh
sudo apt update -y
```
### Download the latest prometheus
at https://prometheus.io/download/  
or for specific version
```sh
wget https://github.com/prometheus/prometheus/releases/download/v3.5.0/prometheus-3.5.0.linux-amd64.tar.gz
```
#### unzip using tar
```sh
tar -xvf prometheus-3.5.0.linux-amd64.tar.gz
```
#### rename the prometheus-3.5.0.linux-amd64 to a shorter name - prometheus
```sh
mv prometheus-3.5.0.linux-amd64 prometheus
```

### 1. Create Prometheus User and Directories
```sh
sudo useradd --no-create-home --shell /bin/false prometheus
sudo mkdir /etc/prometheus
sudo mkdir /var/lib/prometheus
sudo chown prometheus:prometheus /etc/prometheus /var/lib/prometheus
```

### 2. Move Binaries
```sh
sudo cp prometheus/prometheus /usr/local/bin/
sudo cp prometheus/promtool /usr/local/bin/
sudo chown prometheus:prometheus /usr/local/bin/prometheus /usr/local/bin/promtool
```
### 3. Move Configuration File
```sh
sudo cp prometheus/prometheus.yml /etc/prometheus/
sudo chown prometheus:prometheus /etc/prometheus/prometheus.yml
```
Prometheus yaml file is at /etc/prometheus
### 📄 4. Create the Prometheus Service File
Create the file:
```sh
sudo vim /etc/systemd/system/prometheus.service
```

#### Paste the following content:
```sh
[Unit]
Description=Prometheus Monitoring
Wants=network-online.target
After=network-online.target

[Service]
User=prometheus
Group=prometheus
Type=simple
ExecStart=/usr/local/bin/prometheus \
  --config.file=/etc/prometheus/prometheus.yml \
  --storage.tsdb.path=/var/lib/prometheus \
  --storage.tsdb.retention.time=7d \
  --storage.tsdb.retention.size=8GB

[Install]
WantedBy=multi-user.target

```

Save and exit (:wq in Vim).

### 🚀 5. Start and Enable Prometheus
```sh
sudo systemctl daemon-reload
sudo systemctl start prometheus
sudo systemctl enable prometheus
```
#### Check status:
```sh
sudo systemctl status prometheus
```

### 🌐 6. Access Prometheus UI
#### Open your browser and go to:

http://your-server-ip:9090
