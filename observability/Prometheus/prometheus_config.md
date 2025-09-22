## ✅ Basic Recommendeds for Prometheus

### 1. 🔍 To find how many days of data Prometheus stores: 
Prometheus uses the --storage.tsdb.retention.time flag to define how long data is retained.  
Run this command to check the current retention setting:
```
ps aux | grep prometheus
```
If this flag is not set, Prometheus defaults to 15 days.
### 📦 To check how much space is currently used:
This will give you the total size of the prometheus storage directory in a human-readable format (e.g., MB/GB).
```
du -sh /var/lib/prometheus
```

### If you want to monitor Prometheus server in Grafana::
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
