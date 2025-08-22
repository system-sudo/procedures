## ✅ Step-by-Step: Install and Run Grafana as a Service  

### 🧱 Prerequisites:
Linux server (Ubuntu/CentOS)  
Root or sudo access  
Prometheus running (typically on localhost:9090)  
Alertmanager running (typically on localhost:9093)  

### Recommended to follow Official Documentation:
https://grafana.com/docs/grafana/latest/setup-grafana/installation/debian/  

### Step 1️⃣ Install Grafana
```sh
sudo apt-get install -y software-properties-common
sudo add-apt-repository "deb https://packages.grafana.com/oss/deb stable main"
wget -q -O - https://packages.grafana.com/gpg.key | sudo apt-key add -
sudo apt-get update
sudo apt-get install -y grafana
```

### Step 2️⃣ Enable and Start Grafana as a Service

This ensures Grafana starts automatically on boot.
```sh
sudo systemctl daemon-reexec
sudo systemctl enable grafana-server
sudo systemctl start grafana-server
```

### Step 3️⃣ Check Grafana Service Status

```sh
sudo systemctl status grafana-server
```
You should see output indicating that Grafana is active and running.

### Step 4️⃣ Access Grafana Web UI
Open your browser and go to:
```sh
http://<your-server-ip>:3000)
```

Default login:
Username: admin
Password: admin (you’ll be prompted to change it on first login)

Get Prebuild Grafana Dashboards from:
https://grafana.com/grafana/dashboards/



