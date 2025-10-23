## Certbot installation and SSL setup steps

### 🧱 STEP 1 — Install Snap and Core
```sh
sudo apt update -y
sudo apt-get install -y snapd
sudo snap install core
sudo snap refresh core
```
Snap ensures you always get the latest version of Certbot directly from the EFF (Let’s Encrypt team).

### 🧹 STEP 2 — Remove any old Certbot installations
```sh
sudo apt-get remove certbot
```
OR
```sh
sudo apt remove -y certbot python3-certbot-nginx
```

### ⚙️ STEP 3 — Install Certbot via Snap
```sh
sudo snap install --classic certbot
sudo ln -s /snap/bin/certbot /usr/bin/certbot
```

### 🧰 STEP 4 — Check installation
```sh
certbot --version
```

### 🌐 STEP 5 — Obtain your SSL certificate (via HTTP port 80)

#### 🅰️ Option 1 — Standard Nginx (no Cloudflare proxy)
If your domain points directly to your server (if proxied by Cloudflare-Temporarily disable proxy):
```sh
sudo certbot --nginx -d grafana.bellita.co.in
```

Certbot runs its own temporary web server (on port 80), You do not need Nginx.
```sh
sudo certbot certonly --standalone
```

### 🔁 STEP 6 — Test automatic renewal of SSl Cert
```sh
sudo certbot renew --dry-run
```
If it passes ✅, your certificates will auto-renew via a systemd timer (certbot.timer).
Certificates are stored in:
```sh
cd /etc/letsencrypt/live/
```
