## 🛠️ Step-by-Step Guide to Create Prometheus as a Service  
```sh
sudo apt update -y
```
### Download the latest prometheus
#### RUN below cmd to automatically get the latest version:
```sh
sudo curl -s https://api.github.com/repos/prometheus/prometheus/releases/latest \
| grep browser_download_url \
| grep linux-amd64.tar.gz \
| cut -d '"' -f 4 \
| sudo wget -qi -
```
Fetches the latest release URL for Linux from GitHub and downloads it using wget.
#### or Get the specific version from Prometheus GitHub:
at https://prometheus.io/download/  

```sh
wget https://github.com/prometheus/prometheus/releases/download/v3.5.0/prometheus-3.5.0.linux-amd64.tar.gz
```
#### unzip using tar
```sh
tar -xvf prometheus-*.linux-amd64.tar.gz
```
#### rename the prometheus-3.5.0.linux-amd64 to a shorter name - prometheus
```sh
mv prometheus-*.linux-amd64 prometheus
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
  --storage.tsdb.retention.time=14d \
  --storage.tsdb.retention.size=16GB

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
### To Edit your Prometheus config (prometheus.yml):
```sh
sudo vi /etc/prometheus/prometheus.yml
```
Once you've edited the config file, restart Prometheus:
```sh
sudo systemctl daemon-reload
sudo systemctl restart prometheus
```

### 🌐 6. Access Prometheus UI
#### Open your browser and go to:

http://your-server-ip:9090

### ✅ 7. To view the Prometheus Error logs:
```sh
sudo journalctl -u prometheus.service --no-pager -n 20
```
