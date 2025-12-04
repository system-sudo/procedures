## Setup for Alloy to handle Laravel log rotation

Automatically switching to the new day’s file only when Laravel creates it.

### 1. A Script That Manages the Symlink:
This script runs every minute and updates the symlink only when a new daily file actually exists.  
Create:
```sh
nano /opt/devops/scripts/update_laravel_symlink.sh
```
Content:
```sh
#!/bin/bash

LOGDIR="/var/www/html/staging/tracker-backend-v2/storage/logs"
TODAY_FILE="laravel-$(date +%Y-%m-%d).log"
CURRENT_LINK="$LOGDIR/laravel-current.log"

# If Laravel has created today's file, update the symlink
if [ -f "$LOGDIR/$TODAY_FILE" ]; then
    ln -sf "$TODAY_FILE" "$CURRENT_LINK"
fi
```
Make executable:
```sh
chmod +x /opt/devops/scripts/update_laravel_symlink.sh
```

### 2. Systemd timer to run it automatically:
Create a service file:
```sh
nano /etc/systemd/system/update-laravel-symlink.service
```
Content:
```sh
[Unit]
Description=Update Laravel log symlink

[Service]
Type=oneshot
ExecStart=/opt/scripts/update_laravel_symlink.sh
```
Create timer:
```sh
nano /etc/systemd/system/update-laravel-symlink.timer
```
Content:
```sh
[Unit]
Description=Run Laravel symlink updater every minute

[Timer]
OnBootSec=30s
OnUnitActiveSec=60s

[Install]
WantedBy=timers.target
```
Enable:
```sh
systemctl daemon-reload
systemctl enable --now update-laravel-symlink.timer
```

### 3. Update Alloy configuration:
Change path to laravel-current.log
```sh
{ "__path__" = "/var/www/html/staging/tracker-backend-v2/storage/logs/laravel-current.log" },
```
Restart Alloy
```sh
systemctl restart alloy
```
### 4. Check Status:
```sh
systemctl status alloy
systemctl status update-laravel-symlink.service
```
Run:
```sh
ls -l /var/www/html/staging/tracker-backend-v2/storage/logs/laravel-current.log
```

### 5. logging via journalctl:
```sh
journalctl -u update-laravel-symlink.service
```
