## ✅ Basic Recommendeds for Loki

### 1. To check Loki's long-term storage size  
you can inspect the directory where Loki stores its data. Based on your config  
If Loki is using the filesystem as its object store, the path should be :
```
/tmp/loki
```

### 🧾 Command to Check Storage Size  
This will give you the total size of the Loki storage directory in a human-readable format (e.g., MB/GB).
```
du -sh /tmp/loki
```

### If you want to see a breakdown of subdirectories (like chunks, rules, compactor, etc.), use:
```sh
du -sh /tmp/loki/*
```

### 2. Modified Loki Config
```
auth_enabled: false

server:
  http_listen_port: 3100
  grpc_listen_port: 9096
  log_level: debug
  grpc_server_max_concurrent_streams: 1000

common:
  instance_addr: 127.0.0.1
  path_prefix: /tmp/loki
  storage:
    filesystem:
      chunks_directory: /tmp/loki/chunks
      rules_directory: /tmp/loki/rules
  replication_factor: 1
  ring:
    kvstore:
      store: memberlist

memberlist:
  join_members:
    - 127.0.0.1

query_range:
  results_cache:
    cache:
      embedded_cache:
        enabled: true
        max_size_mb: 100

limits_config:
  metric_aggregation_enabled: true
  enable_multi_variant_queries: true
  allow_structured_metadata: false
  retention_period: 336h  # 14 days in hours

schema_config:
  configs:
    - from: 2020-10-24
      store: tsdb
      object_store: filesystem
      schema: v13
      index:
        prefix: index_
        period: 24h

ingester:
  chunk_idle_period: 5m
  chunk_retain_period: 30s
  max_chunk_age: 1h

compactor:
  working_directory: /tmp/loki/compactor
  retention_enabled: true
  delete_request_store: filesystem
  #shared_store: filesystem

pattern_ingester:
  enabled: true
  metric_aggregation:
    loki_address: localhost:3100

ruler:
  alertmanager_url: http://localhost:9093

frontend:
  encoding: protobuf

#analytics:
#reporting_enabled: false
```
