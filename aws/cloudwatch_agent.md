

### Step 1: Attach the correct IAM Role

1. Go to IAM → Roles
2. Create EC2 role (eg.CloudWatchAgentServerRole)
3. Attach this managed policy to the EC2 instance role
  a. CloudWatchAgentServerPolicy - (if metrics/logs are needed)
  b. AmazonSSMManagedInstanceCore - 
4. Attach the role to your EC2 instance (⚠️ EC2 can have only one role attached at a time.)
   🔹 EC2 → Instance → Actions → Security → Modify IAM role
5. Restart the agent (once)
```sh
sudo systemctl restart snap.amazon-ssm-agent.amazon-ssm-agent
```
6. Reboot instance (If required)
Verify from the instance:
```sh
aws sts get-caller-identity
```
```sh
sudo journalctl -u snap.amazon-ssm-agent.amazon-ssm-agent -n 50 --no-pager
```

### Step 2: In AWS Console

1. Go to AWS Systems Manager → Managed Instances
2. Now check the control plane: (wait 1–2 minutes)
   You should see:
* Instance ID: i-02090c613baf7a955
* Status: Online
* Ping status: Healthy


### Step 3: Run interactive config wizard
```sh
sudo /opt/aws/amazon-cloudwatch-agent/bin/amazon-cloudwatch-agent-config-wizard
```
Answer key questions like this:

* Operating system: Linux
* EC2 or on-premises: EC2
* User: default
* StatsD / collectd: No (unless you use them)
* Collect memory metrics? 👉 YES
* Collect swap metrics? 👉 Yes (recommended)
* Collect disk metrics? Optional but useful
* Aggregation interval: 60 seconds (standard)
* Store config in SSM Parameter Store: Yes (recommended)

Check agent status:
```sh
sudo systemctl status amazon-cloudwatch-agent
```
### Step 4: Verify metrics:
Confirm agent picked up memory & disk:
```sh
sudo tail -n 50 /opt/aws/amazon-cloudwatch-agent/logs/amazon-cloudwatch-agent.log
```
You should see entries referencing:
* mem_used_percent
* disk_used_percent
#### Verify metrics in CloudWatch:
* Open Amazon CloudWatch
* Go to Metrics
* Select CWAgent
Choose:
  * InstanceId
  * ImageId / InstanceType

You should see metrics like:
```sh
mem_used_percent
mem_available
swap_used_percent
```

#### Option 2 (Advanced / Explicit): Manually define metrics (JSON)

##### Step 1: Create config file
```sh
sudo nano /opt/aws/amazon-cloudwatch-agent/etc/amazon-cloudwatch-agent.json
```

Paste this minimal but correct config:
```sh
{
  "agent": {
    "metrics_collection_interval": 60,
    "run_as_user": "root"
  },
  "metrics": {
    "append_dimensions": {
      "InstanceId": "${aws:InstanceId}"
    },
    "metrics_collected": {
      "mem": {
        "measurement": [
          "mem_used_percent"
        ]
      },
      "disk": {
        "measurement": [
          "disk_used_percent"
        ],
        "resources": [
          "/"
        ]
      },
      "swap": {
        "measurement": [
          "swap_used_percent"
        ]
      }
    }
  }
}
```

##### Step 2: Apply local config
```sh
sudo /opt/aws/amazon-cloudwatch-agent/bin/amazon-cloudwatch-agent-ctl \
  -a fetch-config \
  -m ec2 \
  -c file:/opt/aws/amazon-cloudwatch-agent/etc/amazon-cloudwatch-agent.json \
  -s
```

Sanity check (optional but revealing)
```sh
free -h
df -h /
```

Then compare:
CLI values
CloudWatch values (after 2–3 minutes)

If they roughly align → setup is correct.
