```sh
input {
  beats {
    port => 5044
  }
}

filter {
  if [log_type] == "slowquery" {
    # Break out slow log fields
    grok {
      match => {
        "message" => [
          "# Time: %{TIMESTAMP_ISO8601:slowlog_time}\n# User@Host: %{DATA:user}\[%{DATA:user_host}\] @ %{DATA:clienthost} \[\]  Id:\s+%{NUMBER:thread_id:int}\n# Query_time: %{NUMBER:query_time:float}\s+Lock_time: %{NUMBER:lock_time:float}\s+Rows_sent: %{NUMBER:rows_sent:int}\s+Rows_examined: %{NUMBER:rows_examined:int}\nSET timestamp=%{NUMBER:set_timestamp};\n%{GREEDYDATA:sql_query}"
        ]
      }
    }

    # Use slowlog timestamp as @timestamp
    date {
      match => ["slowlog_time", "ISO8601"]
      target => "@timestamp"
    }

    # Clean up unwanted fields from Filebeat
    mutate {
      remove_field => ["host", "agent", "ecs", "log", "input", "event", "cloud"]
    }
  }
}

output {
  stdout { codec => rubydebug }

  elasticsearch {
    hosts => ["http://localhost:9200"]
    index => "mysql-slow-logs-%{+YYYY.MM.dd}"
  }
}
```
