### Alloy Config to Monitor Apache Error Logs:
#### Change to the Folder where /etc/default/alloy CONFIG is Pointing:
```sh
cd /opt/alloy
```
#### All Alloy Configs should end with .alloy
```sh
sudo vi error.alloy
```
#### Paste the following:
```
local.file_match "apache_error_logs" {
  path_targets = [{ "__path__" = "/home/ubuntu/error/error8.log" }]
  sync_period  = "5s"
}
 
loki.source.file "apache_error_logs" {
  targets    = local.file_match.apache_error_logs.targets
  tail_from_end = false
  forward_to = [loki.process.add_apache_error_logs.receiver]
}
 
loki.process "add_apache_error_logs" {
 
stage.multiline {
    firstline     = "^\\[[A-Za-z]{3} [A-Za-z]{3} [ 0-9]{2} [0-9:.]+ [0-9]{4}\\]"
  }
 
stage.regex {
    expression = "^\\[(?P<timestamp>[^\\]]+)\\] \\[(?P<module>[^:]+):(?P<level>[^\\]]+)\\] \\[pid (?P<pid>[0-9]+)\\]( \\[client (?P<client_ip>[0-9.]+): (?P<port>[0-9]+)\\])? (?P<error_code>AH[0-9]+): (?P<message>.*)"
  }
 
  stage.labels {
    values = {
      error_code   = "",
    }
  }
 
stage.static_labels {
    values = {
      job         = "error_logs_static",
    }
  }
 
  forward_to = [loki.write.apache_error_logs.receiver]
}
 
loki.write "apache_error_logs" {
  endpoint {
    url = "http://44.202.162.165:3100/loki/api/v1/push"
  }
}
```
