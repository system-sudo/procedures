```

local.file_match "laravel_logs" {
  path_targets = [
    { "__path__" = "/home/ubuntu/laravel/laravel-2025-08-05.log" },
  ]
  sync_period = "5s"
}
 
loki.source.file "laravel_logs" {
  targets       = local.file_match.laravel_logs.targets
  tail_from_end = false
  forward_to    = [loki.process.add_labels_laravel_logs.receiver]
}
 
loki.process "add_labels_laravel_logs" {
  stage.static_labels {
    values = {
      job      = "laravel_logs_static",
    }
  }
 
  stage.multiline {
    firstline = "^\\[[0-9]{4}-[0-9]{2}-[0-9]{2} [0-9]{2}:[0-9]{2}:[0-9]{2}\\]"
  }
 
  stage.regex {
    expression = "^\\[(?P<time>[^\\]]+)\\] (?P<env>[a-zA-Z0-9_-]+)\\.(?P<level>[A-Z]+): (?P<message>.*?)(?:(?P<exception_type>[A-Za-z0-9_\\\\]+Exception))?.*?(?:SQLSTATE\\[[0-9A-Z]+\\](?: \\[(?P<connection_code>[0-9]+)\\])?: [^:]+: (?P<error_code>[0-9]+)? (?P<connection_message>.*connections.*)?)?.*?(?:GET|POST|PUT|DELETE) (?P<api_call>/[A-Za-z0-9/_\\-]*)?.*?(?:App\\\\Http\\\\Controllers\\\\(?P<controller_method>[A-Za-z0-9_@]+))?"
  }
 
  forward_to = [loki.write.laravel_logs.receiver]
}
 
loki.write "laravel_logs" {
  endpoint {
    url = "http://44.202.162.165:3100/loki/api/v1/push"
  }
}
```
