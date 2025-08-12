## 1. No job label
Without a label (like job), your logs might still be in Loki, but they’re hard to find in Grafana unless you query {} without filters. Adding a job label makes them easier to query.

Sample:


local.file_match "slow" {
  path_targets = [{
    __path__ = "/home/ubuntu/logs/*.log"
    job      = "mysql-slow"
  }]
  sync_period = "10s"
}
2. File permissions
Grafana Alloy needs read access to /home/ubuntu/logs/mysql-slow.log.
If Alloy runs as a service, it might not have permission to read files in your home folder.
Run:

bash
Copy
Edit
chmod +r /home/ubuntu/logs/mysql-slow.log
Or move the logs to a folder Alloy can read from, e.g., /var/log/mysql/.

3. tail_from_end behavior
You have:

h
Copy
Edit
tail_from_end = false
This means Alloy will start reading from the beginning of the file.
If the log file is huge, it could take a long time to send everything, and you might think nothing is happening.
If you only want new entries:

hcl
Copy
Edit
tail_from_end = true
4. Loki endpoint
Make sure your Loki endpoint is reachable from the EC2 instance:

bash
Copy
Edit
curl -v http://18.209.166.209:3100/loki/api/v1/push
You should get a 405 Method Not Allowed (normal for GET requests).

5. Full corrected config
hcl
Copy
Edit
local.file_match "slow" {
  path_targets = [{
    __path__ = "/home/ubuntu/logs/*.log"
    job      = "mysql-slow"
  }]
  sync_period = "10s"
}

loki.source.file "slow" {
  targets       = local.file_match.slow.targets
  tail_from_end = true
  forward_to    = [loki.write.slow.receiver]
}

loki.write "slow" {
  endpoint {
    url = "http://18.209.166.209:3100/loki/api/v1/push"
  }
}
