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

### STEP 2 — Generate a service account key (JSON)
```sh
gcloud iam service-accounts keys create ~/adminer-cloudsql.json \
  --iam-account adminer-cloudsql-sa@PROJECT_ID.iam.gserviceaccount.com
```
Secure it:
```sh
chmod 600 ~/adminer-cloudsql.json
```
### STEP 3 — Download Cloud SQL Auth Proxy (v2)
```sh
curl -o cloud-sql-proxy https://storage.googleapis.com/cloud-sql-connectors/cloud-sql-proxy/v2.11.0/cloud-sql-proxy.linux.amd64
chmod +x cloud-sql-proxy
sudo mv cloud-sql-proxy /usr/local/bin/
```
Verify:
```sh
cloud-sql-proxy --version
```
### STEP 4 — Identify your Cloud SQL instance connection name
Example:
```sh
myproj:asia-south1:howdyslim-mysql
```
You can confirm in Cloud SQL → Instance → Overview.
### STEP 5 — Start Cloud SQL Auth Proxy (manual test)
Run this first in foreground to validate:
```sh
cloud-sql-proxy \
  myproj:asia-south1:howdyslim-mysql \
  --address 127.0.0.1 \
  --port 3306 \
  --credentials-file ~/adminer-cloudsql.json
```
Expected output:
```sh
Listening on 127.0.0.1:3306
```
### STEP 6 — Test MySQL connectivity through the proxy
This step proves the entire chain works.
```sh
mysql -h 127.0.0.1 -u howdyslimdev_adminer -p
```
If this succeeds:  
* IAM ✔
* TLS ✔
* Auth plugin ✔
* MySQL ✔
### STEP 7 — Lock down Cloud SQL networking (Optional)
Now that proxy works:
* Remove all Authorized Networks
* Disable public exposure mentally — proxy is the gate
### STEP 8 — Connect thru Adminer
In Adminer login screen:

#### Field	Value
* System	 - MySQL
* Server	 - 127.0.0.1
* Username - howdyslimdev_adminer
* Password - (password)
* Database - (optional)
### STEP 9 — Run Cloud SQL Auth Proxy as a systemd service
Create service file:
```sh
sudo nano /etc/systemd/system/cloud-sql-proxy-adminer.service
```
Paste:
```sh
[Unit]
Description=Cloud SQL Auth Proxy for Adminer
After=network.target

[Service]
Type=simple
User=root
ExecStart=/usr/local/bin/cloud-sql-proxy \
  myproj:asia-south1:howdyslim-mysql \
  --address 127.0.0.1 \
  --port 3306 \
  --credentials-file /root/adminer-cloudsql.json
Restart=always
RestartSec=5

[Install]
WantedBy=multi-user.target
```
Enable + start:
```sh
sudo systemctl daemon-reexec
sudo systemctl daemon-reload
sudo systemctl enable cloud-sql-proxy-adminer
sudo systemctl start cloud-sql-proxy-adminer
```
Check:
```sh
sudo systemctl status cloud-sql-proxy-adminer
```
