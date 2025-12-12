### To make sure the DNS resolves properly:
```sh
host ocr.bellita.co.in
```
OR
```sh
dig +short prometheus.bellita.co.in
```

### Test the syntax before reload:
For Apache
```sh
sudo apachectl configtest
```
For Nginx
```sh
sudo nginx -t
```

### To Enable the site:
Create a symlink:
```sh
sudo ln -s /etc/nginx/sites-available/apis.bellita.co.in.conf /etc/nginx/sites-enabled/
```
