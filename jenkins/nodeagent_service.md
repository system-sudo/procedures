## Run Jenkins Node Agent Automatically on Boot as a Service
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
