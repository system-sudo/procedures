 ## Nginx Reverse Proxy

Nginx as a reverse proxy acts as an intermediary server that forwards client requests to backend servers.  
It enhances security by masking the identity and structure of backend servers and handling SSL/TLS encryption at the proxy level.  
Setting up a reverse proxy in Nginx is straightforward using the proxy_pass directive inside a location block in the server configuration.

### 🔁 Create Nginx site config for reverse proxy (sample of grafana)
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
sudo ln -s /etc/nginx/sites-available/grafana /etc/nginx/sites-enabled/grafana
sudo nginx -t
sudo systemctl reload nginx
```
