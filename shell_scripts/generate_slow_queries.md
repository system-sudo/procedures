## Shell script that will generate a slow query in MySQL by deliberately running a query that takes time to execute.
### This is useful for testing slow query log monitoring with Filebeat and ELK.

### 🛠️ Step-by-Step: Enable Slow Query Logging in MySQL
#### ✅ Step 1: Locate MySQL Configuration File
The config file is usually located at:

Ubuntu/Debian    : /etc/mysql/mysql.conf.d/mysqld.cnf  
Amazon Linux     : /etc/my.cnf  
Docker container : Depends on the image; often /etc/mysql/my.cnf  
You can find it by running:
```sh
mysql --help | grep "Default options"
```

### ✏️ Step 2: Edit the Configuration File
Open the file with a text editor:
```sh
sudo nano /etc/mysql/mysql.conf.d/mysqld.cnf
```

Under the [mysqld] section, add or modify the following lines:
```sh
slow_query_log = 1
slow_query_log_file = /var/log/mysql/mysql-slow.log
long_query_time = 1
log_queries_not_using_indexes = 1
```

slow_query_log = 1     : Enables slow query logging.  
slow_query_log_file    : Path to the log file.  
long_query_time = 1    : Logs queries that take longer than 1 second.  
log_queries_not_using_indexes = 1: Optional, logs queries that don’t use indexes.

### 🔄 Step 3: Restart MySQL
Apply the changes by restarting MySQL:
```sh
sudo systemctl restart mysql
```

### 🔍 Step 4: Verify Logging is Enabled
Log into MySQL:
```sh
mysql -u root -p
```

Run:
```sh
SHOW VARIABLES LIKE 'slow_query_log';
SHOW VARIABLES LIKE 'slow_query_log_file';
SHOW VARIABLES LIKE 'long_query_time';
```

You should see:

slow_query_log = ON  
slow_query_log_file = /var/log/mysql/mysql-slow.log  
long_query_time = 1

### 🐚 Step 5:  Shell Script to Generate a Slow Query in MySQL
open and save the below shell script
```sh
sudo nano generate_slow_queries.sh
```
#### a. default shell script with SLEEP:
```sh
#!/bin/bash

# MySQL credentials
MYSQL_USER="root"
MYSQL_PASSWORD="Sq12345"
MYSQL_HOST="localhost"
MYSQL_DB="mydb"

# Slow query to run every minute
SLOW_QUERY="SELECT SLEEP(5);"

while true; do
    echo "Running slow query at $(date)"
    mysql -u"$MYSQL_USER" -p"$MYSQL_PASSWORD" -h"$MYSQL_HOST" "$MYSQL_DB" -e "$SLOW_QUERY"
    sleep 60
done
```
#### b. Shell Script: Generate a Slow Query in MySQL (NOT TESTED YET)
```sh
#!/bin/bash

# MySQL credentials
MYSQL_USER="root"
MYSQL_PASS="your_password"
MYSQL_DB="test"

# Create test database and table
mysql -u"$MYSQL_USER" -p"$MYSQL_PASS" -e "CREATE DATABASE IF NOT EXISTS $MYSQL_DB;"
mysql -u"$MYSQL_USER" -p"$MYSQL_PASS" "$MYSQL_DB" -e "
CREATE TABLE IF NOT EXISTS slow_table (
    id INT AUTO_INCREMENT PRIMARY KEY,
    data TEXT
);"

# Insert a large number of rows to simulate load
echo "Inserting rows..."
for i in {1..10000}; do
    mysql -u"$MYSQL_USER" -p"$MYSQL_PASS" "$MYSQL_DB" -e "
    INSERT INTO slow_table (data) VALUES (REPEAT('A', 1000));"
done

# Run a deliberately slow query
echo "Running slow query..."
mysql -u"$MYSQL_USER" -p"$MYSQL_PASS" "$MYSQL_DB" -e "
SELECT COUNT(*) FROM slow_table WHERE data LIKE '%ZZZZ%';"

echo "Slow query executed. Check your slow query logs."
```
#### c. Make the Script Executable
Run this command to give execute permission:
```sh
chmod +x ~/generate_slow_queries.sh
```

#### d. Run the Script
```sh
./generate_slow_queries.sh
```
This will start an infinite loop that runs a slow query (SELECT SLEEP(5);) every minute.
#### 🛑 To Stop the Script
Press Ctrl+C in the terminal where it’s running.

#### 🧪 Optional: Run in Background
If you want it to run in the background:
```sh
nohup ./generate_slow_queries.sh > slow-query.log 2>&1 &
```

This will keep it running even after you log out. You can check the output in slow_query.log.


### 📁 Step 6: Check the Log File
After running a slow query (from the shell script), check the log:
```sh
sudo cat /var/log/mysql/mysql-slow.log
```
