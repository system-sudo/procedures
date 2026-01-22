## Step-by-Step Implementation on connecting GCP DB using Cloud Auth Proxy

### Target Architecture
```sh
[ Browser ]
     |
[ Adminer (PHP 7.2) ]
     |
   localhost:3306
     |
[ Cloud SQL Auth Proxy ]
     |
 IAM + TLS
     |
[ Cloud SQL MySQL 8.4 ]
```

### STEP 1 — Create / choose a Service Account
Create a GCP Service Account with role Cloud SQL Client in IAM -> Service Account
* **Type**     : Service account
* **Principal**: cloud-sql-client@trst-score.iam.gserviceaccount.com
* **Role**     : Cloud SQL Client
* **Platform** : Google Cloud
### STEP 2 — Generate a service account key (JSON)
Create a credentials file that the Cloud SQL Auth Proxy can use to authenticate as:
```sh
cloud-sql-client@trst-score.iam.gserviceaccount.com
```
#### 2.1 Create the key (run once)
From a machine with gcloud access (local or server):
```sh
gcloud iam service-accounts keys create \
  ~/cloud-sql-client.json \
  --iam-account cloud-sql-client@trst-score.iam.gserviceaccount.com
```
#### 2.2 Move the key to the server (if created elsewhere)
Copy it to the server where Adminer will run, for example:
```sh
sudo mkdir -p /etc/mysql
sudo nano /etc/mysql/cloud-sql-client.json
```
paste the content from ~/cloud-sql-client.json
#### 2.3 Lock down permissions (mandatory)
On the server Secure it:
```sh
sudo chown root:root /etc/mysql/cloud-sql-client.json
sudo chmod 600 /etc/mysql/cloud-sql-client.json
```
Verify:
```sh
ls -l /etc/mysql/cloud-sql-client.json
```
Expected Out:
```sh
-rw------- 1 root root /etc/mysql/cloud-sql-client.json
```
#### 2.4 Key rotation
Your service account key is a credential.
* Rotate every 90 days (or per policy)
* Replace JSON file
* systemctl restart cloud-sql-proxy
### STEP 3 — Download Cloud SQL Auth Proxy (v2)
#### 3.1 Download the proxy binary
```sh
sudo curl -fLo /usr/local/bin/cloud-sql-proxy \
  https://storage.googleapis.com/cloud-sql-connectors/cloud-sql-proxy/v2.11.0/cloud-sql-proxy.linux.amd64
```
#### 3.2 Make it executable
```sh
sudo chmod +x /usr/local/bin/cloud-sql-proxy
```
#### 3.3 Verify installation
```sh
cloud-sql-proxy --version
```
### STEP 4 — Identify your Cloud SQL instance connection name
#### 4.1 Option A — From Google Cloud Console (most reliable)
1. Go to Cloud SQL
2. Click your MySQL instance
3. Open Overview
4. Copy Instance connection name
Example:
```sh
trst-score:asia-south1:howdyslimdev
```
#### 4.2 Option B — From gcloud CLI
```sh
gcloud sql instances describe INSTANCE_NAME \
  --project trst-score \
  --format='value(connectionName)'
```
Confirm:
* **Project ID** = trst-score
* **Region** = matches instance region (e.g. asia-south1)
* **Instance name** = exact spelling (e.g. howdyslimdev)
### STEP 5 — Start Cloud SQL Auth Proxy (manual test)
#### 5.1 Run this first in foreground to validate:
```sh
sudo cloud-sql-proxy \
  trst-score:asia-south1:trst-score-howdyslimdev \
  --address 127.0.0.1 \
  --port 3306 \
  --credentials-file /etc/mysql/cloud-sql-client.json
```
#### 5.2 Expected successful output
```sh
Listening on 127.0.0.1:3306
Ready for new connections
```
⚠️ Leave this running.  
Do not Ctrl+C yet.
### STEP 6 — Test MySQL connectivity through the proxy
#### 6.1 Open a new terminal (important)
Do not stop the proxy.  
Leave it running in the current terminal.  
Open a second terminal or SSH session to the same server.
#### 6.2 Connect to MySQL via localhost
```sh
mysql -h 127.0.0.1 -P 3306 -u howdyslimdev -p
```
If this succeeds:  
* IAM ✔
* TLS ✔
* Auth plugin ✔
* MySQL ✔
### STEP 7 — Connect thru Adminer
#### 7.1 Open Adminer in your browser
```sh
http://<server-ip>/adminer.php
```
#### 7.2 Fill the Adminer login form EXACTLY as follows
* **System**	 - MySQL
* **Server**	 - 127.0.0.1
* **Username** - howdyslimdev
* **Password** - (password)
* **Database** - (optional)
### STEP 8 — Run Cloud SQL Auth Proxy as a systemd service
#### 8.1 Create the systemd service file
```sh
sudo nano /etc/systemd/system/cloud-sql-proxy.service
```
Paste:
```sh
[Unit]
Description=Cloud SQL Auth Proxy
After=network.target

[Service]
Type=simple
User=root
ExecStart=/usr/local/bin/cloud-sql-proxy \
  trst-score:asia-south1:trst-score-howdyslimdev \
  --address 127.0.0.1 \
  --port 3306 \
  --credentials-file /etc/mysql/cloud-sql-client.json
Restart=always
RestartSec=5

[Install]
WantedBy=multi-user.target
```
#### 8.2 Reload systemd and start the service
```sh
sudo systemctl daemon-reexec
sudo systemctl daemon-reload
sudo systemctl start cloud-sql-proxy
sudo systemctl enable cloud-sql-proxy
```
#### 8.3 Verify service status
```sh
sudo systemctl status cloud-sql-proxy
```
#### 8.4 Stop the foreground proxy (cleanup)
Go back to the terminal where the proxy is running in the foreground and press:
```sh
Ctrl + C
```
#### 8.5 Log & monitor the proxy
```sh
journalctl -u cloud-sql-proxy --since "1 hour ago"
```
### STEP 9 — Lock down Cloud SQL networking (Optional)
Since Adminer works via proxy:
* Go to Cloud SQL → Connections
* Remove all public IP allowlists
Cloud SQL should no longer accept direct internet connections.
