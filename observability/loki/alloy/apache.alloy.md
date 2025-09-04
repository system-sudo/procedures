### Alloy Config to Monitor Apache Logs:
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
    { __path__ = "/var/log/apache2/access.log" },
  ]
  sync_period = "5s"
}

loki.source.file "apache" {
  targets       = local.file_match.apache.targets
  tail_from_end = false
  forward_to    = [loki.process.add_labels.receiver]
}

loki.process "add_labels" {
// Step 1: Merge multi-line log entries (usually not needed for Apache access logs, but safe to keep)
  stage.multiline {
    firstline = "^[0-9]{1,3}\\."  // Match lines starting with an IP address
  }

  // Step 2: Extract fields from Apache "combined" log format
  //  Example log:
  // 192.168.0.1 - - [12/Aug/2025:12:34:56 +0000] "GET /index.html HTTP/1.1" 200 1234 "http://referrer" "User-Agent"
  stage.regex {
    expression = "^(?P<client_ip>\\S+) \\S+ \\S+ \\[(?P<time>[^\\]]+)\\] \"(?P<method>\\S+) (?P<path>[^\\s]+) (?P<protocol>[^\"]+)\" (?P<status>\\d{3}) (?P<bytes_sent>\\d+) \"(?P<referrer>[^\"]*)\" \"(?P<user_agent>[^\"]*)\""
  }



stage.regex {
  expression = "^(?P<client_ip>\\S+) \\S+ \\S+ \\[(?P<time>[^\\]]+)\\] \"(?:(?P<method>\\S+) (?P<path>[^\\s]+) (?P<protocol>[^\"]+)|-)\" (?P<status>\\d{3}) (?P<bytes_sent>\\d+) \"(?P<referrer>[^\"]*)\" \"(?P<user_agent>[^\"]*)\""
}


stage.regex {
  expression = "^(?P<client_ip>\\S+) \\S+ \\S+ \\[(?P<time>[^\\]]+)\\] \"(?:(?P<method>\\S+)(?: (?P<path>[^\\s]+) (?P<protocol>[^\"]+))?|-)\" (?P<status>\\d{3}) (?P<bytes_sent>\\d+) \"(?P<referrer>[^\"]*)\" \"(?P<user_agent>[^\"]*)\""
}



  stage.regex {
    // Capture date, hour, minute, second, method, path, status
    expression = "^(?P<ip>\\S+) \\S+ \\S+ \\[(?P<date>\\d{2}/[A-Za-z]+/\\d{4}):(?P<hour>\\d{2}):(?P<minute>\\d{2}):(?P<second>\\d{2}) [^\\]]+\\] \"(?P<method>[A-Z]+) (?P<path>[^ ]+) [^\"]+\" (?P<status>\\d{3})"
  }


stage.regex {
    expression = "^(?P<ip>[^ ]+) [^ ]+ [^ ]+ \\[(?P<time>[^]]+)\\] \"(?P<method>[A-Z]+) (?P<path>[^ ]+) [^\"]+\" (?P<status>[0-9]+) (?P<size>[0-9]+) (?P<duration>[0-9]+)"
  }


   stage.regex {
    // Extract timestamp and hour from Apache log line
    expression = ".*\\[(?P<date>\\d{2}/[A-Za-z]+/\\d{4}):(?P<hour>\\d{2}):(?P<minute>\\d{2}):(?P<second>\\d{2}).*\\] .*"
  }

stage.regex {
    expression = "^(?P<client_ip>\\S+) \\S+ \\S+ \\[[^\\]]+\\] \\\"(?P<method>[A-Z]+) (?P<path>\\S+) \\S+\\\" (?P<status>\\d{3}) (?P<bytes>\\d+)"
  }

  // Step 3: Add parsed values as labels (don't label high-cardinality fields like path or user_agent)
  stage.labels {
    values = {
      client_ip = "",
      method    = "",
      path      = "",
      bytes     = "",
      hour      = "",
      date      = "",
      status    = "",
    user_agent  = "",
    }
  }

 //  Step 4: Add static labels for all logs
  stage.static_labels {
    values = {
      job      = "apache_logs",
      host     = "apache-server",
      location = "/var/log/apache2",
    }
  }

  forward_to = [loki.write.apache.receiver]
}

loki.write "apache" {
  endpoint {
    url = "http://192.168.8.62:3100/loki/api/v1/push"
  }
}
```
