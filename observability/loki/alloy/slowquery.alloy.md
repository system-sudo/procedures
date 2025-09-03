### Alloy Config to Monitor Slow Query Logs:
#### Chnage to the Folder where /etc/default/alloy CONFIG is Pointing:
```sh
cd /opt/alloy
```
#### All Alloy Configs should end with .alloy
```sh
sudo vi slow.alloy
```
#### Paste the following:
```sh
local.file_match "live" {
  path_targets = [
    { "__path__" = "/var/log/mysql/error.log" },
  ]
  sync_period = "5s"
}

loki.source.file "live" {
  targets       = local.file_match.live.targets
  tail_from_end = false
  forward_to    = [loki.process.parse_slowlog.receiver]
}

loki.process "parse_slowlog" {
  // 1. Merge multi-line MySQL slow query entries into a single log line
  stage.multiline {
    firstline = "^# Time: "
  }

  // 2. Extract fields from the merged log entry
  stage.regex {
    expression = "(?ms)^# Time: (?P<executed_at>\\S+)\\n# User@Host: (?P<user>\\S+)\\[.*?\\] @ (?P<host>\\S+).*?Id: (?P<id>\\d+)\\n# Query_time: (?P<query_time>\\S+)\\s+Lock_time: (?P<lock_time>\\S+)\\s+Rows_sent: (?P<rows_sent>\\d+)\\s+Rows_examined: (?P<rows_examined>\\d+)\\n(?:use (?P<database>[^;]+);\\n)?SET timestamp=\\d+;\\n(?P<sql>.*)"
  }


  /*stage. regex {
    expression = "Query_time: (?P<query_time>[0-9.]+)\\s+Lock_time: (?P<lock_time>[0-9.]+)\\s+Rows_sent: (?P<rows_sent>[0-9]+)\\s+Rows_examined: (?P<rows_examined>[0-9]+)"
  }*/


  stage.regex {
  expression = "Query_time: (?P<query_time>[0-9.]+)\\s+Lock_time: (?P<lock_time>[0-9.]+)\\s+Rows_sent: (?P<rows_sent>[0-9]+)\\s+Rows_examined: (?P<rows_examined>[0-9]+)"
  }

  stage.regex {
  expression = "(?m)^SET timestamp=.*;\\n(?P<query>.*);"
  }

  stage.regex {
    expression = "(?s)(?P<query>(SELECT|INSERT|UPDATE|DELETE).*);"
  }


   stage.regex {
  expression = "Query_time: (?P<query_time>[0-9.]+)\\s+Lock_time: (?P<lock_time>[0-9.]+)\\s+Rows_sent: (?P<rows_sent>[0-9]+)\\s+Rows_examined: (?P<rows_examined>[0-9]+)"
}


// Capture the SQL statement after SET timestamp
stage.regex {
  expression = "(?m)SET timestamp=.*;\\n(?P<query>.*);"
}



  // 3. Add as labels (optional: don't put large SQL text as a label — keep it in log line)
  stage.labels {
    values = {
      executed_at = "",
      user        = "",
      host        = "",
      id          = "",
      query_time  = "",
      database    = "",
      query       = "",
      lock_time   = "",
  rows_sent       = "",
  rows_examined   = "",
      sql         = "",
    }
  }

  // 4. Add static labels for job info
  stage.static_labels {
    values = {
      job      = "live_logs",
      host     = "mysql-server",
      location = "/var/log/mysql",
    }
  }

  forward_to = [loki.write.live.receiver]
}

loki.write "live" {
  endpoint {
    url = "http://192.168.8.62:3100/loki/api/v1/push"
  }
}
```
