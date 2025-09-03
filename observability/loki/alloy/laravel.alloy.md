### Alloy Config to Monitor Apache Error Logs:
#### Chnage to the Folder where /etc/default/alloy CONFIG is Pointing:
```sh
cd /opt/alloy
```
#### All Alloy Configs should end with .alloy
```sh
sudo vi laravel.alloy
```
#### Paste the following:
```sh
local.file_match "laravels11" {
  path_targets = [
    { "__path__" = "/var/www/html/tracker-backend-v2/storage/logs/laravel-2025-09-02.log" },
  ]
  sync_period = "5s"
}

loki.source.file "laravels11" {
  targets       = local.file_match.laravels11.targets
  tail_from_end = false
  forward_to    = [loki.process.add_labels_laravels11.receiver]
}

loki.process "add_labels_laravels11" {
  stage.static_labels {
    values = {
      job      = "laravel_logs11",
      host     = "apps-server1",
      location = "/var/www/html/tracker-backend-v2/storage/logs",
    }
  }

  //  Merge multi-line Laravel log entries
  stage.multiline {
    firstline = "^\\[[0-9]{4}-[0-9]{2}-[0-9]{2} [0-9]{2}:[0-9]{2}:[0-9]{2}\\]"
  }

  // Extract basic Laravel log fields
  stage.regex {
    expression = "^\\[(?P<time>[^\\]]+)\\] (?P<env>[a-zA-Z0-9_-]+)\\.(?P<level>[A-Z]+): (?P<message>.*)$"
  }

  // Extract exception_type from message
  stage.regex {
    expression = ".*\\(?(?P<exception_type>[A-Za-z0-9_\\\\]+Exception).*"
  }

  //  Extract database connection error
  stage.regex {
    expression = ".*SQLSTATE\\[[0-9A-Z]+\\] \\[(?P<connection_code>[0-9]+)\\] (?P<connection_message>.*connections.*)"
  }


  // Extract MySQL/Laravel error code
  stage.regex {
    expression = ".*SQLSTATE\\[[0-9A-Z]+\\]: [^:]+: (?P<error_code>[0-9]+).*"
  }

  //  Extract API call (route or method) from Laravel logs
  // Example matches:
  //   GET /api/user
  //   POST /api/orders
  //   PUT /api/products/5
  //   App\\Http\\Controllers\\UserController@index
  stage.regex {
    expression = ".*(?:GET|POST|PUT|DELETE) (?P<api_call>/[A-Za-z0-9/_\\-]*)|App\\\\Http\\\\Controllers\\\\(?P<controller_method>[A-Za-z0-9_@]+).*"
  }

  forward_to = [loki.write.laravels11.receiver]
}

loki.write "laravels11" {
  endpoint {
    url = "http://192.168.8.62:3100/loki/api/v1/push"
  }
}
```

