## Certbot installation and SSL setup steps

### Installation:
###  Option 1
#### 🧱 STEP 1a — Install Snap and Core
```sh
sudo apt update -y
sudo apt-get install -y snapd
sudo snap install core
sudo snap refresh core
```
Snap ensures you always get the latest version of Certbot directly from the EFF (Let’s Encrypt team).

### 🧹 STEP 1b — Remove any old Certbot installations
```sh
sudo apt-get remove certbot
```
OR
```sh
sudo apt remove -y certbot python3-certbot-nginx
```

### ⚙️ STEP 1c — Install Certbot via Snap
```sh
sudo snap install --classic certbot
sudo ln -s /snap/bin/certbot /usr/bin/certbot
```

###  Option 2

### 🧰 STEP 3 — Check installation
```sh
certbot --version
```

### 🌐 STEP 5 — Obtain your SSL certificate (via HTTP port 80)

If your domain points directly to your server (if proxied by Cloudflare-Temporarily disable proxy):
```sh
sudo certbot --nginx -d grafana.bellita.co.in
```

Certbot runs its own temporary web server (on port 80), You do not need Nginx.
```sh
sudo certbot certonly --standalone
```
Test SSL from Terminal
```sh
curl -Iv https://demo1.trstscore.com
```

### 🔁 STEP 6 — Test automatic renewal of SSL Cert  

You don’t need to enable certbot.timer manually. Snap’s Certbot automatically sets up a renewal service internally.  
Directly go for DRY Run

Check if certbot.timer is Active.
```sh
sudo systemctl status certbot.timer
```
If not then Enable it.
```sh
sudo systemctl enable certbot.timer
sudo systemctl start certbot.timer
```
##### Then Run:
```sh
sudo certbot renew --dry-run
```
If it passes ✅, your certificates will auto-renew via a systemd timer (certbot.timer).
Certificates are stored in:
```sh
cd /etc/letsencrypt/live/
```

### 🔁 STEP 7 — Steps to Remove Certificates
Check existing certificates:
```sh
sudo certbot certificates
```
Delete the specific certificate:
```sh
sudo certbot delete --cert-name apis.bellita.co.in
sudo certbot delete --cert-name back1919.bellita.co.in
```
Verify removal:
```sh
sudo certbot certificates
```
Clean up files manually (optional)
```sh
rm -rf /etc/letsencrypt/live/apis.bellita.co.in
rm -rf /etc/letsencrypt/archive/apis.bellita.co.in
rm -rf /etc/letsencrypt/renewal/apis.bellita.co.in.conf
```
⚠ Important:

Use certbot delete first to avoid breaking renewal configs.
Removing manually without certbot delete can cause renewal errors later.
