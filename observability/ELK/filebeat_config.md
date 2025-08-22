```sh
# ============================== Filebeat inputs ===============================

filebeat.inputs:
  - type: filestream
    id: mysql-slowquery
    enabled: true
    paths:
      - /var/log/mysql/mysql-slow.log

    parsers:
      - multiline:
          type: pattern
          pattern: '^\# Time:'
          negate: true
          match: after

    fields:
      service: mysql
      log_type: slowquery
    fields_under_root: true

```
# ------------------------------ Logstash Output -------------------------------
output.logstash:
  # The Logstash hosts
  hosts: ["54.163.178.2:5044"]
