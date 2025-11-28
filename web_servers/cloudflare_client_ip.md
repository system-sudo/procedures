## To log the original client IPs instead of Cloudflare's proxy IPs in logs

A) APACHE

### Create a temp dir
```sh
sudo mkdir -p /etc/apache2/conf-available
sudo mkdir -p /var/tmp/cloudflare
cd /var/tmp/cloudflare
```

### Fetch the official Cloudflare ip lists
```sh
sudo curl -sS https://www.cloudflare.com/ips-v4 -o /var/tmp/cloudflare/ips-v4.txt
sudo curl -sS https://www.cloudflare.com/ips-v6 -o /var/tmp/cloudflare/ips-v6.txt
```

### Create the remoteip conf that uses CF-Connecting-IP header

remoteip conf will be created at 
```sh
cd /etc/apache2/conf-available
```

```sh
sudo bash <<'EOF'
CFIPS="$( (cat /var/tmp/cloudflare/ips-v4.txt; echo; cat /var/tmp/cloudflare/ips-v6.txt) | xargs )"
cat > /etc/apache2/conf-available/cloudflare-remoteip.conf <<CONF
# Use CF-Connecting-IP header (Cloudflare supplies the original client IP)
RemoteIPHeader CF-Connecting-IP

# Trusted proxies (Cloudflare IPs)
RemoteIPTrustedProxy $CFIPS
CONF
EOF
```

Test the syntax before reload:
```sh
sudo apachectl configtest
```

### Enable the module & config and restart Apache
enable mod_remoteip and the new conf:
```sh
sudo a2enmod remoteip
sudo a2enconf cloudflare-remoteip
sudo systemctl reload apache2
```

restart apache if needed:
```sh
sudo systemctl restart apache2
```

check status:
```sh
sudo systemctl status apache2
```

### Make sure your LogFormat logs the remote IP
Open your apache Conf:
```sh
sudo nano /etc/apache2/sites-available/test.trstscore.com.conf
```
#### This is full snipset Add only BLOCK  # Use custom log format to capture real client IP:
```sh
<VirtualHost *:443>
    ServerName test.trstscore.com

    DocumentRoot /var/www/html

    SSLEngine on
    SSLCertificateFile /etc/letsencrypt/live/test.trstscore.com/fullchain.pem
    SSLCertificateKeyFile /etc/letsencrypt/live/test.trstscore.com/privkey.pem

    # Enable .htaccess and access permissions
    <Directory /var/www/html>
        AllowOverride All
        Require all granted
    </Directory>

    # Use custom log format to capture real client IP
    LogFormat "%a %l %u %t \"%r\" %>s %b \"%{Referer}i\" \"%{User-Agent}i\"" cf_combined
    CustomLog ${APACHE_LOG_DIR}/access.log cf_combined
    ErrorLog ${APACHE_LOG_DIR}/error.log
</VirtualHost>
```
Save and restart Apache:
```sh
sudo systemctl reload apache2
```
### Verify
```sh
sudo tail -f /var/log/apache2/access.log
```

### Updating Cloudflare IPs
Cloudflare occasionally updates ranges.  
You can create a small cron job to refresh /etc/apache2/conf-available/cloudflare-remoteip.conf daily and reload Apache if the list changed:  

#### 🧩 Step 1: Create the update script

Create a Shell Script:
```sh
sudo nano /usr/local/bin/update-cloudflare-ips.sh
```

Paste the following content:
```sh
#!/bin/bash
# ------------------------------------------------------------------------------
# update-cloudflare-ips.sh
# Automatically refresh Cloudflare IP list and update Apache config daily
# Logs all output to /var/log/update-cloudflare-ips.log
# ------------------------------------------------------------------------------
set -euo pipefail

LOG_FILE="/var/log/update-cloudflare-ips.log"
TMP_DIR="/var/tmp/cloudflare"
TMP_IPV4="$TMP_DIR/ips-v4.txt"
TMP_IPV6="$TMP_DIR/ips-v6.txt"
CONF_DIR="/etc/apache2/conf-available"
CONF_FILE="$CONF_DIR/cloudflare-remoteip.conf"

{
echo "=============================="
echo "[INFO] Starting Cloudflare IP update: $(date)"
echo "=============================="

# Ensure Apache config directory exists
sudo mkdir -p "$CONF_DIR"

# Ensure Apache config file exists
sudo touch "$CONF_FILE"

# Ensure temp dir exists
mkdir -p "$TMP_DIR"

# Fetch Cloudflare IP lists
echo "[INFO] Fetching Cloudflare IPv4 list..."
sudo curl -fsSL https://www.cloudflare.com/ips-v4 -o "$TMP_IPV4"

echo "[INFO] Fetching Cloudflare IPv6 list..."
sudo curl -fsSL https://www.cloudflare.com/ips-v6 -o "$TMP_IPV6"

# Check files exist and are not empty
if [[ ! -s "$TMP_IPV4" || ! -s "$TMP_IPV6" ]]; then
    echo "[ERROR] Failed to fetch IP lists. Exiting."
    exit 1
fi

# Combine IPv4 and IPv6 into one space-separated string
CFIPS="$(awk 1 "$TMP_IPV4" "$TMP_IPV6" | tr '\n' ' ')"

# Write Apache config safely
echo "[INFO] Updating Apache RemoteIP configuration..."
sudo tee "$CONF_FILE" > /dev/null <<EOF
# Use CF-Connecting-IP header (Cloudflare supplies the original client IP)
RemoteIPHeader CF-Connecting-IP

# Trusted proxies (Cloudflare IPs)
RemoteIPTrustedProxy $CFIPS
EOF

# Test Apache config (capture stderr)
echo "[INFO] Validating Apache configuration..."
if apachectl configtest 2>&1 | grep -q "Syntax OK"; then
    sudo systemctl reload apache2
    echo "[INFO] Apache configuration valid. Reloaded successfully."
else
    echo "[ERROR] Apache configuration validation failed. Not reloading."
    apachectl configtest 2>&1
    exit 1
fi

echo "[INFO] Cloudflare IP update completed: $(date)"
echo "=============================="
} >> "$LOG_FILE" 2>&1
```
Then make it executable:
```sh
sudo chmod +x /usr/local/bin/update-cloudflare-ips.sh
```
You can manually test it once:
```sh
sudo /usr/local/bin/update-cloudflare-ips.sh
```
Then check the log:
```sh
cat /var/log/update-cloudflare-ips.log
```
#### 🕒 Step 2: Set up a cron job
Edit the root crontab:
```sh
sudo crontab -e
```
Add this line at the bottom:
* To run it daily
```sh
0 3 * * * /usr/local/bin/update-cloudflare-ips.sh >> /var/log/update-cloudflare-ips.log 2>&1
```
Runs every day at 3:00 AM  
* To run it weekly
```sh
0 3 * * 1 /usr/local/bin/update-cloudflare-ips.sh >> /var/log/update-cloudflare-ips.log 2>&1
```
(Runs every Monday at 3:00 AM.)
Check it’s listed:
```sh
sudo crontab -l
```
