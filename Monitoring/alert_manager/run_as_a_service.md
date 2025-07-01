## 🛠️ Step-by-Step Guide to Create Prometheus as a Service  
```sh
sudo apt update -y
```
### 🛠️ Step 1: Download and Install Alertmanager
at https://prometheus.io/download/
or for specific version
```sh
wget https://github.com/prometheus/alertmanager/releases/download/v0.28.1/alertmanager-0.28.1.linux-amd64.tar.gz
```
```sh
tar -xvf alertmanager-0.28.1.linux-amd64.tar.gz
```
#### rename the alertmanager-0.28.1.linux-amd64 to a shorter name - alertmanager
```sh
mv alertmanager-0.28.1.linux-amd64 alertmanager
```

### 👤 Step 2: Create Alertmanager User and Directories
```sh
sudo useradd --no-create-home --shell /bin/false alertmanager
sudo mkdir /etc/alertmanager /var/lib/alertmanager
sudo cp alertmanager/alertmanager /usr/local/bin/
sudo cp alertmanager/amtool /usr/local/bin/
sudo chown alertmanager:alertmanager /usr/local/bin/alertmanager /usr/local/bin/amtool
sudo chown -R alertmanager:alertmanager /etc/alertmanager /var/lib/alertmanager
```

### ⚙️ Step 3: Configure Alertmanager

#### 🔗 Create an Incoming Webhook in Microsoft Teams
Open Microsoft Teams and go to the channel where you want to receive alerts.  
Click on the three dots (⋯) next to the channel name.  
Select “Connectors”.  
In the search box, type “Incoming Webhook”.  
Click “Configure” next to Incoming Webhook.  
Give your webhook a name (e.g., Prometheus Alerts) and optionally upload an image.  
Click “Create”.  
Copy the Webhook URL that is generated. You’ll use this in your Alertmanager config.  

```sh
sudo vim /etc/alertmanager/alertmanager.yml
```

#### Paste the following configuration (replace the webhook URL with your actual MS Teams webhook):

```sh
global:
  resolve_timeout: 5m

route:
  receiver: 'msteams'

receivers:
  - name: 'msteams'
    webhook_configs:
      - url: 'https://outlook.office.com/webhook/your-webhook-url' # replace the webhook URL with your actual MS Teams webhook 
        send_resolved: true
```

#### Set permissions:
```sh
sudo chown alertmanager:alertmanager /etc/alertmanager/alertmanager.yml
```

### 🧾 Step 4: Create Alertmanager Systemd Service
Create the file:
```sh
sudo vim /etc/systemd/system/alertmanager.service
```

#### Paste the following content:
```sh
[Unit]
Description=Prometheus Alertmanager
Wants=network-online.target
After=network-online.target

[Service]
User=alertmanager
Group=alertmanager
Type=simple
ExecStart=/usr/local/bin/alertmanager \
  --config.file=/etc/alertmanager/alertmanager.yml \
  --storage.path=/var/lib/alertmanager

[Install]
WantedBy=multi-user.target
```

Save and exit (:wq in Vim).

### 🚀 Step 5: Start and Enable Alertmanager
```sh
sudo systemctl daemon-reload
sudo systemctl start alertmanager
sudo systemctl enable alertmanager
```
#### Check status:
```sh
sudo systemctl status alertmanager
```

### 🌐 6. Access Alertmanager UI
#### Open your browser and go to:

http://<your-server-ip>:9093
