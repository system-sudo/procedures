## ✅ Set up Grafana HTTPS for secure web traffic  

### 🧱 Prerequisites:
Grafana  
Nginx   

### Recommended to follow Official Documentation:
```
https://grafana.com/docs/grafana/latest/setup-grafana/set-up-https/ 
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

### 🧱 STEP 1 — Install Snap and Core
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
### 🔁 STEP 7 Create Nginx site config for Grafana (manual method)
```sh
sudo nano /etc/nginx/sites-available/grafana.bellita.co.in.conf
```
paste the following:
```sh
# Redirect all HTTP (port 80) requests to HTTPS (port 443)
server {
    listen 80;
    server_name grafana.bellita.co.in;
# Redirect all HTTP -> HTTPS
    return 301 https://$host$request_uri;
}

# HTTPS server block
server {
    listen 443 ssl http2;
    server_name grafana.bellita.co.in;

    # SSL certificate and key
    ssl_certificate /etc/letsencrypt/live/grafana.bellita.co.in/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/grafana.bellita.co.in/privkey.pem;

    # Recommended SSL settings
    ssl_session_cache shared:SSL:10m;
    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_ciphers HIGH:!aNULL:!MD5;
    ssl_prefer_server_ciphers off;

    # Optional: force HTTPS for future requests
    add_header Strict-Transport-Security "max-age=31536000; includeSubDomains; preload" always;

    # Proxy requests to Grafana running locally on port 3000
    location / {
        proxy_pass http://127.0.0.1:3000/;
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
sudo ln -s /etc/nginx/sites-available/grafana.bellita.co.in.conf /etc/nginx/sites-enabled/
sudo nginx -t
sudo systemctl reload nginx
```
Check Nginc status:
```sh
sudo systemctl status nginx
```

### 🧾 STEP 8 — Configure Grafana HTTPS and restart Grafana  
Open Grafana config:
```sh
sudo nano /etc/grafana/grafana.ini
```

edit the following configuration parameters Under the [server] section:
```sh
[server]
# Bind only to localhost — Nginx proxies connections
http_addr = 127.0.0.1
http_port = 3000

# Domain Grafana should use in generated URLs
domain = grafana.bellita.co.in

# This ensures links and redirects use https://grafana.bellita.co.in/
root_url = https://grafana.bellita.co.in/

# If you serve Grafana from a sub-path, set true (not needed here)
serve_from_sub_path = false

# Optional
;cert_key = /etc/grafana/grafana.key
;cert_file = /etc/grafana/grafana.crt
;enforce_domain = False
;protocol = https
```

Save and restart Grafana:
```sh
sudo systemctl restart grafana-server
```
Check Grafana Service Status
```sh
sudo systemctl status grafana-server
```
You should see output indicating that Grafana is active and running.

### Step 9 Access Grafana Web UI
Open your browser and go to:
```sh
https://grafana.bellita.co.in/ # use your domain name
```

Default login:
Username: admin
Password: admin (you’ll be prompted to change it on first login)

### 🧾 If something fails, check Grafana and Nginx logs:
```sh
sudo journalctl -u grafana-server -e
```
```sh
sudo tail -n 200 /var/log/nginx/error.log
sudo tail -n 200 /var/log/nginx/access.log
```
