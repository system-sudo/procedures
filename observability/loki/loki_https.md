## ✅ Set up Loki HTTPS for secure web traffic  

### 🧱 Prerequisites:
Loki  
Nginx   

### Recommended to follow Official Documentation:
```
https://grafana.com/docs/loki/latest/configure/
```

### Install nginx (if not present)
```sh
sudo apt update
sudo apt install -y nginx
sudo systemctl enable --now nginx
```
check status
```sh
sudo systemctl status nginx
```

### 🧱 STEP 1 — Install Snap and Core (Step 1-3 if Certbot not present)
```sh
sudo apt update
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
sudo certbot --nginx -d loki.pro1hs.com
```

Certbot runs its own temporary web server (on port 80), You do not need Nginx.
```sh
sudo certbot certonly --standalone
```

### 🔁 STEP 6 — Test automatic renewal of SSL Cert
```sh
sudo certbot renew --dry-run
```
If it passes ✅, your certificates will auto-renew via a systemd timer (certbot.timer).
Certificates are stored in:
```sh
cd /etc/letsencrypt/live/
```

### 🔁 STEP 7 Create Nginx site config for Loki (manual method)
```sh
sudo nano /etc/nginx/sites-available/loki.pro1hs.com.conf
```
paste the following:
```sh
# Redirect all HTTP (port 80) requests to HTTPS (port 443)
server {
    listen 80;
    server_name loki.pro1hs.com;
# Redirect all HTTP -> HTTPS
    return 301 https://$host$request_uri;
}

# HTTPS server block
server {
    listen 443 ssl http2;
    server_name loki.pro1hs.com;

    # SSL certificate and key
    ssl_certificate /etc/letsencrypt/live/loki.pro1hs.com/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/loki.pro1hs.com/privkey.pem;

    # Recommended SSL settings
    ssl_session_cache shared:SSL:10m;
    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_ciphers HIGH:!aNULL:!MD5;
    ssl_prefer_server_ciphers off;

    # Optional: force HTTPS for future requests
    add_header Strict-Transport-Security "max-age=31536000; includeSubDomains; preload" always;

    # Proxy requests to Loki running locally on port 3000
    location / {
        proxy_pass http://127.0.0.1:3100/;
        proxy_http_version 1.1;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;

        # WebSocket support
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "upgrade";
    }

    # Optional: serve ACME challenge files (for certificate renewals)
    location ~ /.well-known/acme-challenge/ {
        root /var/www/html;
    }
}
```
Enable and test:
```sh
sudo ln -s /etc/nginx/sites-available/loki.pro1hs.com.conf /etc/nginx/sites-enabled/
sudo nginx -t
sudo systemctl reload nginx
```
Check Nginx status:
```sh
sudo systemctl status nginx
```

### Step 8 Access Loki Web UI
Open your browser and go to:
```sh
https://loki.pro1hs.com/ # use your domain name
```

### 🧾 If something fails, check Loki and Nginx logs:
```sh
sudo journalctl -u loki -f
```
```sh
sudo tail -n 200 /var/log/nginx/error.log
sudo tail -n 200 /var/log/nginx/access.log
```
