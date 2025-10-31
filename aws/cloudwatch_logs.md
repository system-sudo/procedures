## Monitoring logs using Amazon CloudWatch

### Step 1: Download and install the CloudWatch Agent:
```sh
sudo apt-get update -y
wget https://s3.amazonaws.com/amazoncloudwatch-agent/ubuntu/amd64/latest/amazon-cloudwatch-agent.deb
sudo dpkg -i amazon-cloudwatch-agent.deb
```
### Step 2: Create CloudWatch Agent Configuration
Create the config file:
```sh
sudo nano /opt/aws/amazon-cloudwatch-agent/bin/config.json
```
Paste the following configuration: (To monitor Apache Logs)
```sh
{
  "agent": {
    "metrics_collection_interval": 60,
    "run_as_user": "root"
  },
  "logs": {
    "logs_collected": {
      "files": {
        "collect_list": [
          {
            "file_path": "/var/log/apache2/access.log",
            "log_group_name": "ubuntu-apache2-access-log",
            "log_stream_name": "{instance_id}/access.log",
            "timestamp_format": "%b %d %H:%M:%S",
            "multi_line_start_pattern": "^[0-9]{1,3}\\.[0-9]{1,3}\\.[0-9]{1,3}\\.[0-9]{1,3}"
          },
          {
            "file_path": "/var/log/apache2/error.log",
            "log_group_name": "ubuntu-apache2-error-log",
            "log_stream_name": "{instance_id}/error.log",
            "timestamp_format": "%a %b %d %H:%M:%S.%f %Y"
          }
        ]
      }
    },
    "log_stream_name": "{instance_id}"
  }
}
```
You can adjust timestamp_format based on your actual log format.  
Edit "collect_list": To add more log location to Monitor.

### Step 3: Start the CloudWatch Agent
```sh
sudo /opt/aws/amazon-cloudwatch-agent/bin/amazon-cloudwatch-agent-ctl \
  -a fetch-config \
  -m ec2 \
  -c file:/opt/aws/amazon-cloudwatch-agent/bin/config.json \
  -s
```
To check agent status:
```sh
sudo /opt/aws/amazon-cloudwatch-agent/bin/amazon-cloudwatch-agent-ctl -m ec2 -a status
```
```sh
systemctl status amazon-cloudwatch-agent.service
```
### Step 4: IAM Role

* Ensure your EC2 instance has permission to publish logs to CloudWatch:  
* Attach IAM Role to EC2  
* Create an IAM role with the policy CloudWatchAgentServerPolicy and attach it to your EC2 instance.  
* You can attach these from the AWS Console (EC2 → Instances → Actions → Security → Modify IAM role)

### Step 5: Verify in CloudWatch Console

* Go to CloudWatch > Log Groups in the AWS Console and check for log_group_name:  
eg:
ubuntu-apache2-access-log
* You should see logs streaming in under the respective log streams.

### Step 6: Common troubleshooting
```sh
sudo journalctl -u amazon-cloudwatch-agent -f --no-pager
```
```sh
sudo cat /opt/aws/amazon-cloudwatch-agent/logs/amazon-cloudwatch-agent.log
```
### Step 7: (Optional) Use the config wizard
```sh
sudo /opt/aws/amazon-cloudwatch-agent/bin/amazon-cloudwatch-agent-config-wizard
```
It guides you through typical choices and writes the JSON.
