### Alloy Config to Monitor Apache Error Logs:
#### Change to the Folder where /etc/default/alloy CONFIG is Pointing. eg:
```sh
cd /opt/alloy
```
#### All Alloy Configs should end with .alloy
```sh
sudo vi error.alloy
```
#### Paste the following:
```sh
local.file_match "apache_errors11" {
  path_targets = [
    { __path__ = "/var/log/apache2/error.log" }, // adjust if needed
  ]
  sync_period = "5s"
}

loki.source.file "apache_errors11" {
  targets       = local.file_match.apache_errors11.targets
  tail_from_end = false
  forward_to    = [loki.process.apache_errors11.receiver]
}

loki.process "apache_errors11" {
  // Step 1: Multiline (important if PHP/Apache logs span multiple lines)
   stage.timestamp {
  source = "timestamp"
  format = "Mon Jan 02 15:04:05.000000 2006"
}



  // Step 2: Parse Apache error log format with PHP warnings
  stage.regex {
  expression = "^\\[(?P<timestamp>.+?)\\] \\[(?P<module>.+?):(?P<level>.+?)\\] \\[pid (?P<pid>\\d+)\\] \\[client (?P<client_ip>[\\d\\.]+):(?P<client_port>\\d+)\\] PHP (?P<php_level>\\w+):\\s+(?P<message>.+?) in (?P<file>.+?) on line (?P<line>\\d+), referer: (?P<referer>.+)$"
}


stage.regex {
    expression = "\\[(?P<timestamp>[^\\]]+)\\] (?P<env>[^.]+)\\.(?P<level>[A-Z]+): (?P<message>.*)"
  }

stage.regex {
    expression = "resulted in a `(?P<status>[0-9]{3})"
  }


  // Step 3: Extract useful labels from fields
  stage.labels {
    values = {
      level     = "",
      client    = "",
      file      = "",
      status    = "",
      env       = "",
      php_level = "",
    }
  }

  // Step 4: Add static labels for identification (job, host, location)
  stage.static_labels {
    values = {
      job      = "apache_errors11",
      host     = "dev-server",     // change this to actual hostname (or use ${HOSTNAME})
      location = "/var/log/apache2",      // change this to your datacenter/region
    }
  }

  // Step 5: Map the extracted timestamp into Loki’s time
  stage.timestamp {
    source = "timestamp"
    format = "Mon Jan 02 15:04:05.000000 2006"
  }

  forward_to = [loki.write.apache_errors11.receiver]
}

// Step 6: Send parsed logs to Loki
loki.write "apache_errors11" {
  endpoint {
    url = "http://192.168.8.62:3100/loki/api/v1/push"   // change if Loki is remote
  }
}
```
