### To Check mysqld_Exporter Logs for Errors:
Run:
```sh
sudo journalctl -u mysqld_exporter.service --no-pager | tail -n 50
```
