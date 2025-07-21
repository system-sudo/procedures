# 🔧 Step-by-Step: Setting Up Public IP for On-Permisis Private IP Jenkins with ngrok  
### 1. Install ngrok  

Go to 
```bash
https://ngrok.com/download
```
follow procedure at https://ngrok.com/download

### 2. Sign Up and Get Your Auth Token
Create a free account at ngrok.com
After logging in, go to your dashboard and copy your auth token
Run this command to set it up:
```bash
ngrok config add-authtoken <your-auth-token>
```

### 3. Start ngrok Tunnel
Assuming Jenkins is running on port 8080:
```bash
ngrok http 8080
```

This will give you a public URL like:
https://abcd1234.ngrok.io

### 4. Set Up Webhooks (e.g., GitHub)
In your GitHub repo:

Go to Settings → Webhooks
Add a new webhook:
Payload URL: https://abcd1234.ngrok.io/github-webhook/
Content type: application/json
Choose events (e.g., push)

### 5. Configure Jenkins Job
In your Jenkins pipeline job:

Enable "GitHub hook trigger for GITScm polling"
Make sure your repo is configured correctly in the job

### 6. Run it as a Service
```bash
vi /etc/systemd/system/ngrok.service
```
paste this content
```bash
[Unit]
Description=ngrok
 
[Service]
ExecStart=/usr/local/bin/ngrok http 8080
Restart=always
 
[Install]
WantedBy=multi-user.target
```

```bash
sudo systemctl enable ngrok
sudo systemctl start ngrok
sudo systemctl status ngrok
```
get public IP from here
```bash
curl http://localhost:4040/api/tunnels
```
Repeat step 3, 4, 5
