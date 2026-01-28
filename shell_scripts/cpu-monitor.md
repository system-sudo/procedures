## Heading

### 1️⃣ Detect sustained CPU pressure
#### Trigger
* THRESHOLD=70
* SUSTAIN_COUNT=3
* systemd timer every 1 minute
That means:
➡️ CPU > 70% for ~3 minutes continuously
#### Sustained-state implementation (state file)
It will store the current consecutive breach count.
```sh
STATE_FILE="/var/run/cpu_monitor.state"
```
It will be automatically created by script.

### 2️⃣ Auto-capture MySQL context
We capture:
* SHOW FULL PROCESSLIST
* Active thread count
* Queries running > 1s
* Optional: InnoDB status (commented, heavy)

We do read-only SQL, no config changes.
⚠️ This requires:
* root socket access or
* /root/.my.cnf with credentials
(I’ll assume socket access since you’re root.)

### ✅ Script (production-grade)
```sh
nano /usr/local/bin/cpu-monitor.sh
```
Paste the following:
```sh
#!/bin/bash
#
# cpu-monitor.sh
# Sustained CPU monitoring with MySQL context capture
#

THRESHOLD=70
SUSTAIN_COUNT=3
STATE_FILE="/var/run/cpu_monitor.state"

TOP_N=10
MYSQL_CPU_THRESHOLD=50   # %CPU for mysqld to trigger MySQL capture

log() {
    echo "$@"
}

get_cpu_usage() {
    PREV=($(grep '^cpu ' /proc/stat))
    sleep 1
    CURR=($(grep '^cpu ' /proc/stat))

    PREV_IDLE=${PREV[4]}
    CURR_IDLE=${CURR[4]}

    PREV_TOTAL=0
    CURR_TOTAL=0
    for v in "${PREV[@]:1}"; do PREV_TOTAL=$((PREV_TOTAL + v)); done
    for v in "${CURR[@]:1}"; do CURR_TOTAL=$((CURR_TOTAL + v)); done

    DIFF_IDLE=$((CURR_IDLE - PREV_IDLE))
    DIFF_TOTAL=$((CURR_TOTAL - PREV_TOTAL))

    (( DIFF_TOTAL == 0 )) && echo 0 && return
    echo $(( (100 * (DIFF_TOTAL - DIFF_IDLE)) / DIFF_TOTAL ))
}

CPU_USAGE=$(get_cpu_usage)
LOAD_AVG=$(cut -d' ' -f1-3 /proc/loadavg)

COUNT=0
[ -f "$STATE_FILE" ] && COUNT=$(cat "$STATE_FILE")

if [ "$CPU_USAGE" -ge "$THRESHOLD" ]; then
    COUNT=$((COUNT + 1))
else
    COUNT=0
fi

echo "$COUNT" > "$STATE_FILE"

# Not sustained yet → exit quietly
[ "$COUNT" -lt "$SUSTAIN_COUNT" ] && exit 0

log "=================================================="
log "SUSTAINED HIGH CPU DETECTED"
log "Time         : $(date)"
log "CPU Usage    : ${CPU_USAGE}%"
log "Load Average : ${LOAD_AVG}"
log "Consecutive  : ${COUNT} minutes"
log

log "Top CPU processes:"
ps -eo pid,ppid,user,comm,%cpu,%mem --sort=-%cpu | head -n $((TOP_N + 1))
log

# MySQL context capture (only if mysqld is hot)
MYSQL_CPU=$(ps -C mysqld -o %cpu= | awk '{sum+=$1} END {print int(sum)}')

if [ "$MYSQL_CPU" -ge "$MYSQL_CPU_THRESHOLD" ]; then
    log "---- MySQL Context (mysqld CPU: ${MYSQL_CPU}%) ----"

    mysql --batch --skip-column-names <<EOF
SHOW FULL PROCESSLIST;
SELECT COUNT(*) AS active_threads FROM information_schema.processlist WHERE COMMAND != 'Sleep';
SELECT ID,USER,HOST,DB,COMMAND,TIME,STATE,LEFT(INFO,200)
FROM information_schema.processlist
WHERE TIME > 1
ORDER BY TIME DESC;
EOF

    log
    # Uncomment ONLY if needed (heavy)
    # mysql -e "SHOW ENGINE INNODB STATUS\G"
fi

exit 0
```
Make it executable:
```sh
chmod +x /usr/local/bin/cpu-monitor.sh
```

### 🔧 systemd integration
If you want cron the use this  
edit root’s crontab:
```sh
crontab -e
```
Add:
```sh
* * * * * /opt/devops/scripts/cpu_monitor.sh >> /var/log/cpu_monitor.cron 2>&1
```
Save and exit.  
Verify it’s really root’s crontab:
```sh
crontab -l
```
#### systemd gives you:
* structured logs (journalctl)
* clean failure visibility
* proper lifecycle management
#### 1️⃣ Service unit
```sh
nano /etc/systemd/system/cpu-monitor.service
```
Paste the following:
```sh
[Unit]
Description=Sustained CPU Monitor with MySQL Context

[Service]
Type=oneshot
ExecStart=/usr/local/bin/cpu-monitor.sh
```
#### 2️⃣ Timer unit
```sh
nano /etc/systemd/system/cpu-monitor.timer
```
Paste the following:
```sh
[Unit]
Description=Run CPU monitor every minute

[Timer]
OnBootSec=1min
OnUnitActiveSec=1min
AccuracySec=10s

[Install]
WantedBy=timers.target
```
#### 3️⃣ Enable & start
```sh
systemctl daemon-reexec
systemctl daemon-reload
systemctl enable --now cpu-monitor.timer
```
Verify:
```sh
systemctl list-timers | grep cpu-monitor
```
### 🔍 How to read the logs
Everything goes to journald now:
```sh
journalctl -u cpu-monitor.service
```
Live view during load:
```sh
journalctl -u cpu-monitor.service -f
```

