## ✅ Basic Recommendeds for Jenkins

### 1. To Fix permissions on the workspace
Grant Full Permission to the User which handles Jenkin activity eg. jenkin, ubuntu

```
sudo chown -R ubuntu:ubuntu /var/www/html/staging/tracker-vite
sudo chmod -R 775 /var/www/html/staging/tracker-vite
```
