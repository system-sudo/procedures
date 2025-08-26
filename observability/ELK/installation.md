

## Install Kibana with Debian package
#### Follow Official documentaion:
```
https://www.elastic.co/docs/deploy-manage/deploy/self-managed/install-kibana-with-debian-package
```

### Step #1:Install Java for Elastic Stack
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
#### Elasticsearch is the core component of the ELK Stack, used for search and analytics. We need to import the public signing key and add the Elasticsearch APT repository to your system.
```sh
wget -qO - https://artifacts.elastic.co/GPG-KEY-elasticsearch | sudo gpg --dearmor -o /usr/share/keyrings/elasticsearch-keyring.gpg
```

#### Add the repository definition.
```sh
echo "deb [signed-by=/usr/share/keyrings/elasticsearch-keyring.gpg] https://artifacts.elastic.co/packages/8.x/apt stable main" | sudo tee /etc/apt/sources.list.d/elastic-8.x.list
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
You can access it using browser with your Public IP address:9200 port which is a default port for Elasticksearch.

#### You should see a JSON response.
<img width="622" height="362" alt="image" src="https://github.com/user-attachments/assets/5394f2a3-268d-4450-ab89-1b6e93976d08" />

### Step #4:Install Logstash
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
#### Kibana provides a web interface for visualizing data from Elasticsearch. Install Kibana using following command.Ubuntu-based server monitoringLong-term support for Elastic Stack

sudo apt-get install kibana
How to Install Elastic Stack on Ubuntu 24.04 LTS 23
Start and enable the Kibana service.

sudo systemctl start kibana
sudo systemctl enable kibana
How to Install Elastic Stack on Ubuntu 24.04 LTS 24
Check the status of Kibana:

sudo systemctl status kibana
How to Install Elastic Stack on Ubuntu 24.04 LTS 25
Step #6:Configure Kibana on Ubuntu 24.04 LTS
To configure Kibana for external access, edit the configuration file.Ubuntu-based server monitoring

sudo nano /etc/kibana/kibana.yml
How to Install Elastic Stack on Ubuntu 24.04 LTS 26
Uncomment and adjust the following lines to bind Kibana to all IP addresses and connect it to Elasticsearch.


server.port: 5601
server.host: "0.0.0.0"
elasticsearch.hosts: ["http://localhost:9200"]
How to Install Elastic Stack on Ubuntu 24.04 LTS 27
Restart Kibana to apply the changes.

sudo systemctl restart kibana
How to Install Elastic Stack on Ubuntu 24.04 LTS 28
Access the Kibana interface by navigating to http://<your-server-ip>:5601 in your web browser. This will open the Kibana dashboard where you can start exploring your data.

How to Install Elastic Stack on Ubuntu 24.04 LTS 29
You can start by adding integrations or Explore on my own.








### Sources:
1. https://www.youtube.com/watch?v=GZudei1xTnc
2. https://www.fosstechnix.com/how-to-install-elastic-stack-on-ubuntu-24-04/
3. https://dev.to/devops_methodology_d2b67f/real-time-projectelk-stack-set-up-with-logs-monitoring-setup-3c2b
4. https://www.elastic.co/docs/get-started/
