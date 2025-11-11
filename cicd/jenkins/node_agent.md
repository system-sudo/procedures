# 🧭 Overview

* Prepare the agent machine
* Create the node in Jenkins UI
* Connect the agent to the controller
* Verify and test the connection

## 🖥️ Step 1: Prepare the Agent Machine (192.168.6.2)
### ✅ Requirements

Make sure the agent machine has:

* Java installed (Jenkins agents need it)
* A user with permission to run builds (e.g., jenkins or ubuntu)

### 🧩 Install Java (if not installed)
```sh
sudo apt update
sudo apt install openjdk-17-jre -y
java -version
```

## ⚙️ Step 2: Create Agent Node in Jenkins UI

### Open Jenkins web UI:
eg: 👉 http://192.168.8.39:8080/manage

Go to Manage Jenkins → Nodes → New Node

Fill in:
#### Node name:
node-agent1 (or any name you prefer)
Select Permanent Agent

#### Number executors:
1 (or more, depending on CPU)

#### Remote root directory:
/home/jenkins (or any path)

#### Labels:
staging. (or any name you prefer - This will be used in the pipeline)

#### Usage:
"Use this node as much as possible" or "Only build jobs with label expressions matching this node"

#### Launch method: choose one:

✅ Launch agent by connecting it to the controller (recommended, more secure)  
or Launch agent via SSH (simpler setup if you can SSH from controller to agent)

## 🚀 Step 3: Agent Connects to Controller

#### Create the working directory:
(as set in the Jenkins Node Config)
```sh
mkdir -p /home/jenkins
```
<img width="1867" height="372" alt="image" src="https://github.com/user-attachments/assets/97952ea2-eae8-4eb6-94c0-e156cad87d48" />

This will be automatically avaiable in Connect option of Jenkins Node in UI
#### Download agent jar:
```sh
cd /home/jenkins
curl -sO http://192.168.8.39:8080/jnlpJars/agent.jar
```

#### To Run the Agent (Manual)
```sh
java -jar agent.jar -url http://192.168.8.39:8080/ -secret 573a18cdd927d81dbadddc8470957405e48f5d7a1306dacdde6d1fa31a37afd1 -name test -webSocket -workDir "/home/jenkins"
```
### To Run Jenkins Node Agent Automatically on Boot as a Service
```sh
sudo nano /etc/systemd/system/jenkins-agent.service
```
### Paste the following:
```sh
[Unit]
Description=Jenkins Agent
After=network.target

[Service]
User=jenkins
WorkingDirectory=/home/jenkins
ExecStart=/usr/bin/java -jar /home/jenkins/agent.jar -jnlpUrl http://192.168.8.39:8080/computer/uat-agent/jenkins-agent.jnlp -secret <SECRET_KEY> -workDir /home/jenkins
Restart=always

[Install]
WantedBy=multi-user.target
```

### Then enable and start:
```sh
sudo systemctl daemon-reload
sudo systemctl enable jenkins-agent
sudo systemctl start jenkins-agent
```

Check Status
```sh
sudo systemctl status jenkins-agent
```

## 🧪 Step 4: Verify Connection

In Jenkins → Manage Jenkins → Nodes, check the new node shows online.

Run a test job restricted to this node using:
```sh
agent { label 'staging' }
stages {
    stage('Test') {
        steps {
            sh 'hostname && whoami && pwd'
        }
    }
}
```
