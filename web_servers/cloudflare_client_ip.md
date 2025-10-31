## To log the original client IPs instead of Cloudflare's proxy IPs in logs

### Create a temp dir
```sh
sudo mkdir -p /etc/apache2/conf-available
cd /tmp
```

### fetch the official Cloudflare ip lists
```sh
curl -sS https://www.cloudflare.com/ips-v4 -o /tmp/ips-v4.txt
curl -sS https://www.cloudflare.com/ips-v6 -o /tmp/ips-v6.txt
```

### create the remoteip conf that uses CF-Connecting-IP header
```sh
sudo bash <<'EOF'
CFIPS="$( (cat /tmp/ips-v4.txt; echo; cat /tmp/ips-v6.txt) | xargs )"
cat > /etc/apache2/conf-available/cloudflare-remoteip.conf <<CONF
# Use CF-Connecting-IP header (Cloudflare supplies the original client IP)
RemoteIPHeader CF-Connecting-IP

# Trusted proxies (Cloudflare IPs)
RemoteIPTrustedProxy $CFIPS
CONF
EOF
```

Test the syntax before reload
```sh
sudo apachectl configtest
```

### Enable the module & config and restart Apache:
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
sudo nano /etc/apache2/sites-available/app.trstscore.com.conf
```
Add these lines:
```sh
LogFormat "%a %l %u %t \"%r\" %>s %b \"%{Referer}i\" \"%{User-Agent}i\"" combined_real
CustomLog ${APACHE_LOG_DIR}/app_access.log combined_real
```
Save and restart Apache:
```sh
sudo systemctl reload apache2
```
### Verify
```sh
sudo tail -n 20 /var/log/apache2/access.log
```

### Automate updating Cloudflare IPs
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
# ------------------------------------------------------------------------------

set -e

# Temp files
TMP_IPV4="/tmp/ips-v4.txt"
TMP_IPV6="/tmp/ips-v6.txt"
CONF_FILE="/etc/apache2/conf-available/cloudflare-remoteip.conf"

# Fetch latest IP ranges from Cloudflare
curl -sS https://www.cloudflare.com/ips-v4 -o "$TMP_IPV4"
curl -sS https://www.cloudflare.com/ips-v6 -o "$TMP_IPV6"

# Build a clean IP list with space separation
CFIPS="$( (cat "$TMP_IPV4"; echo; cat "$TMP_IPV6") | xargs )"

# Update Apache config
sudo bash <<CONF
cat > "$CONF_FILE" <<EOF
# Use CF-Connecting-IP header (Cloudflare supplies the original client IP)
RemoteIPHeader CF-Connecting-IP

# Trusted proxies (Cloudflare IPs)
RemoteIPTrustedProxy $CFIPS
EOF
CONF

# Validate Apache configuration before reload
if apachectl configtest | grep -q "Syntax OK"; then
    systemctl reload apache2
    echo "[INFO] Cloudflare IPs updated and Apache reloaded successfully."
else
    echo "[ERROR] Apache config validation failed. Not reloading." >&2
    exit 1
fi
```
Then make it executable:
```sh
sudo chmod +x /usr/local/bin/update-cloudflare-ips.sh
```
You can manually test it once:
```sh
sudo /usr/local/bin/update-cloudflare-ips.sh
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
