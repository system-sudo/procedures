### Alloy Config to Monitor Slow Query Logs:
#### Change to the Folder where /etc/default/alloy CONFIG is Pointing:
```sh
cd /opt/alloy
```
#### All Alloy Configs should end with .alloy
```sh
sudo vi slow.alloy
```
#### Paste the following:
```sh
local.file_match "slow_logs" {
  path_targets = [
    { "__path__" = "/home/ubuntu/logs/mysql-slow7.log" },
  ]
  sync_period = "5s"
}
 
loki.source.file "slow_logs" {
  targets       = local.file_match.slow_logs.targets
  tail_from_end = false
  forward_to    = [loki.process.parse_slow_logs.receiver]
}
 
loki.process "parse_slow_logs" {
  // 1. Merge multi-line MySQL slow query entries into a single log line
  stage.multiline {
    firstline = "^# Time: "
  }
 
  // 2. Extract query_time and SQL query
  stage.regex {
    expression = "(?ms)# Query_time: (?P<query_time>\\S+).*?SET timestamp=\\d+;\\n(?P<query>.*);"
  }
 
  // 3. Add extracted fields as labels
  stage.labels {
    values = {
      query_time = "",
    }
  }
 
  // 4. Add static labels
  stage.static_labels {
    values = {
      job      = "slowquery_logs",
      }
  }
 
  forward_to = [loki.write.slow_logs.receiver]
}
 
loki.write "slow_logs" {
  endpoint {
    url = "http://54.226.66.148:3100/loki/api/v1/push"
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
sudo journalctl -u alloy.service -f
```
