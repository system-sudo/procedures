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
Verify metrics are available
```sh
http://ip:9090/metrics
```

Grafana dashboard setup
```sh
https://grafana.com/grafana/dashboards/15489-prometheus-2-0-stats/
```
```sh
https://grafana.com/grafana/dashboards/3662-prometheus-2-0-overview/
```
