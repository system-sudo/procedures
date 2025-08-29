### To Check Elasticsearch Logs for Errors:
Run:
```sh
sudo journalctl -xeu elasticsearch.service --no-pager | tail -n 50
```
