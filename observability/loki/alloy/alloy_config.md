## 1. No job label
Without a label (like job), your logs might still be in Loki, but they’re hard to find in Grafana unless you query {} without filters.  
Adding a job label makes them easier to query.

Sample:
In Process Block
```bash
  stage.static_labels {
    values = {
      job      = "apache_logs10",
    }
  }
```

## 2. tail_from_end behavior
You have:

tail_from_end = false  

This means Alloy will start reading from the beginning of the file.
If the log file is huge, it could take a long time to send everything, and you might think nothing is happening.
If you only want new entries:
```bash
tail_from_end = true
```
## 3. Loki endpoint
Make sure your Loki endpoint is reachable from the EC2 instance:
```bash
curl -v http://18.209.166.209:3100/loki/api/v1/push
```
You should get a 405 Method Not Allowed (normal for GET requests).

## 4. Basic Alloy config  
Move to CONFIG Location:
```sh
cd /opt/alloy
```
Create a File FILENAME.alloy
```sh
sudo vi apache.alloy
```
Paste the following:
```bash
local.file_match "apache" {
  path_targets = [
    { __path__ = "/home/ubuntu/logs/access10a.log" },
  ]
  sync_period = "5s"
}

loki.source.file "apache" {
  targets       = local.file_match.apache.targets
  tail_from_end = false
  forward_to    = [loki.process.add_labels.receiver]
}

loki.process "add_labels" {
  stage.multiline {
    firstline = "^[0-9]{1,3}\\."  // Match lines starting with an IP address
  }

  stage.regex {
    expression = "^(?P<client_ip>\\S+) \\S+ \\S+ \\[[^\\]]+\\] \\\"(?P<method>[A-Z]+) (?P<path>\\S+) [^\\\"]+\\\" (?P<status>\\d{3})"
  }

  stage.labels {
    values = {
      client_ip = "",
      method    = "",
      path      = "",
      status    = "",
    }
  }

  stage.static_labels {
    values = {
      job      = "apache_logs10",
    }
  }

  forward_to = [loki.write.apache.receiver]
}

loki.write "apache" {
  endpoint {
    url = "http://54.158.147.172:3100/loki/api/v1/push"
  }
}
```
## 5. Logging Alloy startup errors to a file
Edit the systemd unit override:

```bash
sudo systemctl edit alloy
```
Add:

```bash
[Service]
StandardOutput=append:/var/log/alloy-startup.log
StandardError=append:/var/log/alloy-startup.log
```
Save and reload:

```bash
sudo systemctl daemon-reload
sudo systemctl restart alloy
```
Now, even if it crashes instantly, you can see:

```bash
cat /var/log/alloy-startup.log
```

## 5. Alloy tailing positions:
Every Alloy Config is tailed and its position is recorded in:

```bash
nano /var/lib/alloy/data/loki.source.file.laravels11/positions.yml
```
