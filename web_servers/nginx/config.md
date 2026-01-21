### To make sure the DNS resolves properly:
```sh
host ocr.bellita.co.in
```
OR
```sh
dig +short prometheus.bellita.co.in
```

### Test the syntax before reload:
For Nginx
```sh
sudo nginx -t
```

### To Enable the site:
Create a symlink:
```sh
sudo ln -s /etc/nginx/sites-available/apis.bellita.co.in /etc/nginx/sites-enabled/
```
Reload Nginx:
```sh
sudo systemctl reload nginx
```
### To Disable the site:
Remove it from active config:
```sh
sudo rm /etc/nginx/sites-enabled/stgocr.trstscore.com
```
Test again
```sh
sudo nginx -t
```
Reload
```sh
sudo systemctl reload nginx
```
### To Remove the site:
If you truly want it gone (not just disabled):
```sh
sudo rm /etc/nginx/sites-available/stgocr.trstscore.com
```
Test again
```sh
sudo nginx -t
```
Reload
```sh
sudo systemctl reload nginx
```
### List active virtual hosts/site:
```sh
sudo nginx -T | grep sites-
```
```sh
sudo nginx -T | grep "server_name"
```
### Locate main Nginx config:
```sh
sudo nano /etc/nginx/nginx.conf
```
