
# Masking Real API Domain Behind a Proxy Using Nginx

## Objective
The goal is to hide the real API domain (`apis.bellita.co.in`) from the frontend and instead expose a proxy domain (`back1919.bellita.co.in`). This helps improve security and prevents direct exposure of the backend API.  

Note : Both domain should point same ip

### 1. Create a single certificate covering both domains
```sh
sudo certbot --nginx -d apis.bellita.co.in -d back1919.bellita.co.in
```

Use the apis certificate ONLY if it includes both DNS:
```sh
sudo openssl x509 -in /etc/letsencrypt/live/apis.bellita.co.in/fullchain.pem -noout -text | grep DNS
```
### 2. Configure Nginx for Both Domains
Create a configuration file in `/etc/nginx/sites-available/` (e.g., `apis.bellita.co.in.conf`):
```sh
sudo nano /etc/nginx/sites-available/apis.bellita.co.in.conf
```
Paste the following:
```nginx
# Redirect HTTP to HTTPS
server {
    listen 80;
    server_name apis.bellita.co.in back1919.bellita.co.in; # Including both domains
    return 301 https://$host$request_uri; # redirect HTTP -> HTTPS
}

# HTTPS configuration
server {
    listen 443 ssl http2;
    server_name apis.bellita.co.in back1919.bellita.co.in; # Including both domains

    ssl_certificate /etc/letsencrypt/live/apis.bellita.co.in/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/apis.bellita.co.in/privkey.pem;

    root /usr/share/nginx/html;
    index index.php;

    access_log /usr/share/nginx/html/logs/access.log;
    error_log /usr/share/nginx/html/logs/error.log;

    add_header Strict-Transport-Security "max-age=31536000" always;

    # Enable gzip compression
    gzip on;
    gzip_disable "msie6";
    gzip_types text/plain text/css application/json application/javascript text/xml application/xml application/xml+rss text/javascript;

    # API routing
    location /api/ {
        try_files $uri /server/php/Slim/public/index.php?$query_string;
    }

    location /api10/ {
        try_files $uri /server/php/Slim/public/api.php?$query_string;
    }

    # PHP handling
    location ~ \.php$ {
        include fastcgi_params;
        fastcgi_split_path_info ^(.+\.php)(/.+)$;
        fastcgi_param SCRIPT_FILENAME $document_root$fastcgi_script_name;
        fastcgi_pass unix:/var/run/php/php7.2-fpm.sock;
        fastcgi_index index.php;
        fastcgi_read_timeout 180;
        fastcgi_param PATH_INFO $fastcgi_path_info;
    }

    # Default location
    location / {
        try_files $uri $uri/ =404;
    }
}
```
### 2. Enable the Site and Reload Nginx
```sh
ln -s /etc/nginx/sites-available/apis.bellita.co.in.conf /etc/nginx/sites-enabled/
nginx -t
systemctl reload nginx
```

### 3. Frontend Changes

Update the frontend to call https://back1919.bellita.co.in/api/... instead of https://apis.bellita.co.in/api/....

### 4. How It Works
* Frontend sees: back1919.bellita.co.in
* Nginx internally routes: requests to Slim PHP backend under /server/php/Slim/public/
* Real API domain remains hidden from browser inspection tools.

### 5. Requirement
* Ensure SSL certificates are valid for both domains.
* Update DNS records for both domains to point to the same server.
* Test using curl or browser developer tools.
