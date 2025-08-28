## Elastic Stack Installation for Ubuntu 24.04 LTS  
#### * Elasticsearch
- Stores and Indexs Logs.  
#### * Logstash
- Processes and tranforms logs before storing them in Elasticsearch.  
#### * Kibana - Provides visualization.  
#### * Filebeat - Forwards logs from the application to logstash.

### Step #1:Install Java for Elastic Stack
Note: You might want to check if Elastic 9.x still requires Java for all components. Installing Java is optional unless you're using custom setups or older versions.
#### Start by updating your system’s package index.
```sh
sudo apt update
```

#### Install the apt-transport-https package to access repository over HTTPS.
```sh
sudo apt install apt-transport-https
```

#### Elastic Stack components require Java. We will install OpenJDK 11, which is a widely used open-source implementation of the Java Platform.

```sh
sudo apt install openjdk-11-jdk -y
```

#### After installation, verify that Java is correctly installed by checking its version.
```sh
java -version
```

#### To ensure stack components can locate Java, we need to set the JAVA_HOME environment variable. Open the environment file.

```sh
sudo nano /etc/environment
```

#### Add the following line at the end of the file.
```sh
JAVA_HOME="/usr/lib/jvm/java-11-openjdk-amd64"
```
#### Apply the changes by reloading the environment.
```sh
source /etc/environment
```

#### Verify that JAVA_HOME is set correctly.
```sh
echo $JAVA_HOME
```

### Step #2:Install ElasticSearch
#### Follow Official documentation at:
```
https://www.elastic.co/docs/deploy-manage/deploy/self-managed/install-elasticsearch-with-debian-package
```
#### We need to import the public signing key and add the Elasticsearch APT repository to your system.
```sh
wget -qO - https://artifacts.elastic.co/GPG-KEY-elasticsearch | sudo gpg --dearmor -o /usr/share/keyrings/elasticsearch-keyring.gpg
```

#### Add the repository definition.
```sh
echo "deb [signed-by=/usr/share/keyrings/elasticsearch-keyring.gpg] https://artifacts.elastic.co/packages/9.x/apt stable main" | sudo tee /etc/apt/sources.list.d/elastic-9.x.list
```

#### Update the package lists again to include the new Elasticsearch repository.

```sh
sudo apt-get update
```
#### Install Elasticsearch.

```sh
sudo apt-get install elasticsearch
```
#### Start Elasticsearch and configure it to run at system startup.
```sh
sudo systemctl start elasticsearch
sudo systemctl enable elasticsearch
```
#### Verify that Elasticsearch is running.

```sh
sudo systemctl status elasticsearch
```

### Step #3:Configure Elasticsearch

#### To allow external access to Elasticsearch, modify the configuration file.
```sh
sudo nano /etc/elasticsearch/elasticsearch.yml
```
#### Find the network.host setting, uncomment it, and set it to 0.0.0.0 to bind to all available IP addresses and uncomment the discovery section to specify the initial nodes for cluster formation discovery.seed_hosts: []
<img width="903" height="541" alt="image" src="https://github.com/user-attachments/assets/fbb23bd1-f66f-4514-a8d3-5521bb6f3898" />

#### For a basic setup (not recommended for production), disable security features.
<img width="951" height="697" alt="image" src="https://github.com/user-attachments/assets/a8d4b739-8067-4cb1-a23a-5802ab0614da" />

#### Restart Elasticsearch to apply the changes.
```sh
sudo systemctl restart elasticsearch
```

#### To confirm that Elasticsearch is set up correctly, send a test HTTP request using curl.
```sh
curl -X GET "server-ip:9200"
```
#### You should see a JSON response.
<img width="622" height="362" alt="image" src="https://github.com/user-attachments/assets/5394f2a3-268d-4450-ab89-1b6e93976d08" />

You can access it using browser with your Public IP address:9200 port which is a default port for Elasticksearch.

### Step #4:Install Logstash
#### Follow Official documentation at:
```
https://www.elastic.co/docs/reference/logstash/installing-logstash
```
#### We need to import the public signing key and add the APT repository to your system.
```sh
wget -qO - https://artifacts.elastic.co/GPG-KEY-elasticsearch | sudo gpg --dearmor -o /usr/share/keyrings/elastic-keyring.gpg
```

#### Add the repository definition.
```sh
echo "deb [signed-by=/usr/share/keyrings/elastic-keyring.gpg] https://artifacts.elastic.co/packages/9.x/apt stable main" | sudo tee -a /etc/apt/sources.list.d/elastic-9.x.list
```

#### Logstash is used to process and forward log data to Elasticsearch. Install Logstash using following command.
```sh
sudo apt-get install logstash -y
```
#### Start and enable Logstash.
```sh
sudo systemctl start logstash
sudo systemctl enable logstash
```

#### Verify the service status.
```sh
sudo systemctl status logstash
```
### Step #5:Install Kibana
#### Follow Official documentation at:
```
https://www.elastic.co/docs/deploy-manage/deploy/self-managed/install-kibana-with-debian-package
```
#### We need to import the public signing key and add the APT repository to your system.
### NOTE: both Elasticsearch/Kibana use same key and Repo, hence no need to add again.
```sh
wget -qO - https://artifacts.elastic.co/GPG-KEY-elasticsearch | sudo gpg --dearmor -o /usr/share/keyrings/elasticsearch-keyring.gpg
```
#### Add the repository definition.
```sh
echo "deb [signed-by=/usr/share/keyrings/elasticsearch-keyring.gpg] https://artifacts.elastic.co/packages/9.x/apt stable main" | sudo tee /etc/apt/sources.list.d/elastic-9.x.list
```

#### Kibana provides a web interface for visualizing data from Elasticsearch. Install Kibana using following command.
```sh
sudo apt-get install kibana
```
Start and enable the Kibana service.
```sh
sudo systemctl start kibana
sudo systemctl enable kibana
```
Check the status of Kibana:
```sh
sudo systemctl status kibana
```
### Step #6:Configure Kibana on Ubuntu 24.04 LTS
#### To configure Kibana for external access, edit the configuration file.
```sh
sudo nano /etc/kibana/kibana.yml
```
#### Uncomment and adjust the following lines to bind Kibana to all IP addresses and connect it to Elasticsearch.

```sh
server.port: 5601
server.host: "0.0.0.0"
elasticsearch.hosts: ["http://localhost:9200"] # If Elasticsearch is on a different server than kibana, replace localhost with its IP.
```
<img width="1010" height="721" alt="image" src="https://github.com/user-attachments/assets/06dec190-4cfb-4bb0-b137-c99d183cd718" />

#### Restart Kibana to apply the changes.
```sh
sudo systemctl restart kibana
```
#### Access the Kibana interface by navigating to http://<your-server-ip>:5601 in your web browser. This will open the Kibana dashboard where you can start exploring your data.
<img width="1024" height="516" alt="image" src="https://github.com/user-attachments/assets/42ba991d-ad56-47ae-b26f-51bf67384ab6" />

Step #7:Install Filebeat on Ubuntu 24.04 LTS
Filebeat is a lightweight shipper used to forward and centralize log data. Install Filebeat using following command.

sudo apt-get install filebeat
How to Install Elastic Stack on Ubuntu 24.04 LTS 31
Open the Filebeat configuration file to send logs to Logstash.

sudo nano /etc/filebeat/filebeat.yml
How to Install Elastic Stack on Ubuntu 24.04 LTS 32
Comment out the Elasticsearch output section.

# output.elasticsearch:
 #  hosts: ["localhost:9200"]
Uncomment and configure the Logstash output section.

output.logstash:
  hosts: ["localhost:5044"]
How to Install Elastic Stack on Ubuntu 24.04 LTS 33
Enable the system module, which collects log data from the local system.

sudo filebeat modules enable system
How to Install Elastic Stack on Ubuntu 24.04 LTS 34
Set up Filebeat to load the index template into Elasticsearch.

sudo filebeat setup --index-management -E output.logstash.enabled=false -E 'output.elasticsearch.hosts=["0.0.0.0:9200"]'
How to Install Elastic Stack on Ubuntu 24.04 LTS 35
Start and enable the Filebeat service.

sudo systemctl start filebeat
sudo systemctl enable filebeat
How to Install Elastic Stack on Ubuntu 24.04 LTS 36
Ensure Elasticsearch is receiving data from Filebeat by checking the indices.

curl -XGET "localhost:9200/_cat/indices?v"
You should see output indicating the presence of indices created by Filebeat.

How to Install Elastic Stack on Ubuntu 24.04 LTS 37
You can access it using browser using http://<your-server-ip>:9200/_cat/indices?v

### Sources:
1. https://www.youtube.com/watch?v=GZudei1xTnc
2. https://www.fosstechnix.com/how-to-install-elastic-stack-on-ubuntu-24-04/
3. https://dev.to/devops_methodology_d2b67f/real-time-projectelk-stack-set-up-with-logs-monitoring-setup-3c2b
4. https://www.elastic.co/docs/get-started/
