## ✅ Basic Recommendeds for Prometheus

### 🔍 To find how many days of data Prometheus stores: 
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

### To view the Full Prometheus Error Message:
This will show the last 20 lines of logs for the Prometheus service.
```
sudo journalctl -u prometheus.service --no-pager -n 20
```

### To to Validate the Prometheus.yml Config :
This will give you a clear error message if there's a syntax or structural issue in the YAML file.
```
promtool check config /etc/prometheus/prometheus.yml
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
