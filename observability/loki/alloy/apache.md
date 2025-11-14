### Alloy Config to Monitor Apache Access Logs:
#### Change to the Folder where /etc/default/alloy CONFIG is Pointing:
```sh
cd /opt/alloy
```
#### All Alloy Configs should end with .alloy
```sh
sudo vi apache.alloy
```
#### Paste the following:
```sh
local.file_match "apache" {
  path_targets = [
    { __path__ = "/home/ubuntu/logs/access1-Copy.log" },
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
      job      = "apache_logs",
    }
  }

  forward_to = [loki.write.apache.receiver]
}

loki.write "apache" {
  endpoint {
    url = "http://54.81.159.127:3100/loki/api/v1/push"
  }
}
```
#### Restart Alloy
```sh
sudo systemctl restart alloy
sudo systemctl status alloy
```
#### To view Alloy log files for any Errors:
```sh
sudo journalctl -u alloy.service -n 50 --no-pager
```
