## 🛠️ Step-by-Step Guide to create Alerting rules:

### ✅ 1. Create Alert Rule for CPU Usage  
  
#### Create a file called /etc/prometheus/alert.rules.yml:
```sh
sudo vim /etc/prometheus/alert.rules.yml
```

#### Paste the following content:
```sh
groups:
  - name: cpu_alerts
    rules:
      - alert: HighCPUUsage
        expr: (100 - (avg by(instance) (rate(node_cpu_seconds_total{mode="idle"}[2m])) * 100)) > 50
        for: 2m
        labels:
          severity: warning
        annotations:
          summary: "High CPU usage detected on {{ $labels.instance }}"
          description: "CPU usage is above 50% for more than 2 minutes."
```

Then, include this file in your prometheus.yml:
```sh
sudo vim /etc/prometheus/prometheus.yml
```

```sh
rule_files:
  - "alert_rules.yml"
```


✅ 2. Verify Alertmanager Configuration
Your alertmanager.yml looks mostly correct. Just ensure the formatting is clean and the webhook URL is valid:
```sh
global:
  resolve_timeout: 5m

route:
  receiver: 'msteams'

receivers:
  - name: 'msteams'
    webhook_configs:
      - url: 'https://secqureone.webhook.office.com/webhookb2/229733ca-daf5-4902-b0cf-5af2c24be947@99305083-0700-45c6-8ab2-19cb66e5502c/IncomingWebhook/401130c13b924cec870e6c01ba5fd7a0/b9ef76cd-2fbc-4f1e-95ac-34e35c516221/V2ynObFR1Si3jr46ePqX9xQtb5Hefg8ABVz2qBWMCIHVw1'
        send_resolved: true
```

✅ 3. Restart Prometheus and Alertmanager
After making these changes, restart both services:
```sh
sudo systemctl restart prometheus
sudo systemctl restart alertmanager
```
