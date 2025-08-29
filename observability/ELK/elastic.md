## ✅ Basic Recommendeds for Elasticsearch

### 1. To Check Elasticsearch Logs for Errors:
Run:
```sh
sudo journalctl -xeu elasticsearch.service --no-pager | tail -n 50
```

### 2. To set fixed memory for Elasticsearch:  

Elasticsearch is not explicitly configured to use a fixed heap size. In this case, it will fall back to the default behavior, which can vary depending on the version and environment, but often it tries to allocate half of the available system memory.
#### eg:
With 8 GB total RAM, the safe approach is:
-Xms4g
-Xmx4g

#### Why 4 GB?
  50% of total RAM is recommended for Elasticsearch.
  Leaves ~4 GB for OS, Logstash, Kibana, and disk caching.
  Keeps the JVM heap stable (min = max).

#### Logstash
  Default heap is -Xms1g -Xmx1g, which usually works for moderate pipelines.
  If your pipelines are heavy, you could increase to 2 GB max, but on an 8 GB server, leaving it at 1 GB is safer.

#### Kibana
  Node.js-based, usually <500 MB. Defaults are fine.

### To apply this:  
#### Edit the file:
```sh
sudo nano /etc/elasticsearch/jvm.options
```
#### Find the lines:
```sh
## -Xms4g
## -Xmx4g
```
#### Change them to:
```sh
-Xms4g
-Xmx4g
```
🧠 Why This Matters
Uncommenting and setting heap size ensures Elasticsearch doesn't dynamically resize the heap, which can cause performance issues.
Matching Xms and Xmx avoids GC overhead and memory fragmentation.
#### Save and exit, then restart Elasticsearch:
```sh
sudo systemctl restart elasticsearch
```







✅ Recommendation for your setup (8 GB server):

Service	Heap / Memory
Elasticsearch	4 GB (-Xms4g -Xmx4g)
Logstash	1 GB (default)
Kibana	Default

This setup balances memory without starving the OS.
