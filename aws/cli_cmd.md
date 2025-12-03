### 1. Ready-to-run bash script that will show:
✔ Instance Type, Instance ID, Availability Zone, Public IP  
✔ CPU cores  
✔ Memory (Total, Free, Available)  
✔ Disk usage

#### a. Create the file:
```sh
nano ec2-info.sh
```
#### b. Paste the script:
```bash

#!/bin/bash

# Get IMDSv2 token
TOKEN=$(curl -s -X PUT "http://169.254.169.254/latest/api/token" \
  -H "X-aws-ec2-metadata-token-ttl-seconds: 21600")

# Fetch EC2 metadata
INSTANCE_TYPE=$(curl -s -H "X-aws-ec2-metadata-token: $TOKEN" \
  http://169.254.169.254/latest/meta-data/instance-type)
INSTANCE_ID=$(curl -s -H "X-aws-ec2-metadata-token: $TOKEN" \
  http://169.254.169.254/latest/meta-data/instance-id)
AZ=$(curl -s -H "X-aws-ec2-metadata-token: $TOKEN" \
  http://169.254.169.254/latest/meta-data/placement/availability-zone)
PUBLIC_IP=$(curl -s -H "X-aws-ec2-metadata-token: $TOKEN" \
  http://169.254.169.254/latest/meta-data/public-ipv4)

# System info
CPU_CORES=$(nproc)
MEM_TOTAL=$(free -h | awk '/Mem:/ {print $2}')
MEM_FREE=$(free -h | awk '/Mem:/ {print $4}')
MEM_AVAIL=$(free -h | awk '/Mem:/ {print $7}')
DISK_USAGE=$(df -h / | awk 'NR==2 {print $2 " total, " $4 " free"}')

# Display info
echo "===== EC2 Instance Info ====="
echo "Instance ID:    $INSTANCE_ID"
echo "Instance Type:  $INSTANCE_TYPE"
echo "Availability Zone: $AZ"
echo "Public IP:      $PUBLIC_IP"
echo
echo "===== System Info ====="
echo "CPU Cores:      $CPU_CORES"
echo "Memory:         Total: $MEM_TOTAL | Free: $MEM_FREE | Available: $MEM_AVAIL"
echo "Disk (/):       $DISK_USAGE"
```
#### c. Make it executable:
```sh
chmod +x ec2-info.sh
```
#### d. Run it:
```sh
./ec2-info.sh
```
