## Configure SMTP in Grafana

### Step 1 – Generate SMTP credentials  
Recommended : Use company SMTP
If using Gmail:
* Enable 2-Step Verification
* Create an App Password
* Note the 16-character password (you’ll never see it again)

### Step 2 – Locate Grafana config file
```sh
sudo nano /etc/grafana/grafana.ini
```
#### Edit [smtp] section
Find or add:
```sh
# smtp for linear mail alert
enabled = true
host = smtp.gmail.com:587
user = awslearn776@gmail.com
password = nupo nwai jixy jwjf
from_address = awslearn776@gmail.com
from_name = Grafana Alerts
startTLS_policy = Opportunistic
```
### Step 3 – Restart Grafana
```sh
sudo systemctl restart grafana-server
```
Verify:
```sh
sudo systemctl status grafana-server
```
### Step 4 – Validate SMTP at Grafana level
```sh
sudo journalctl -u grafana-server -n 100 --no-pager
```
You should not see:
* SMTP not configured
* failed to send email

### Step 5 – Create Email Contact Point
In Grafana UI:
* Alerting → Contact points
* New contact point
* Type: Email
* Addresses: monitoring-d5aae28b5efc@intake.linear.app
* Save
* Click Test

### Step 6 – Confirm in Linear
Go to Linear → your team:

* You should see a new issue created via email
* Title will be based on email subject
* Body will contain Grafana alert text
