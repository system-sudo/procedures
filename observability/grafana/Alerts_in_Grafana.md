## 🛠 Steps to Create Alerts in Grafana

### 🧩 Step 1: Create a Webhook in Microsoft Teams  
1. Open Microsoft Teams.
2. Go to the channel where you want to receive alerts. (Channel should be public to receive notification)
<img width="263" height="308" alt="image" src="https://github.com/user-attachments/assets/debc2b0d-60c9-404e-aa52-de3717c4e731" />

3. Click the three dots (⋯) next to the channel name → Workflows.
4. Select "Send webhook alerts to a channel.
5. Give it a name (e.g., "Grafana Alerts").
6. Click Add workflow, and copy the Webhook URL provided.

### ⚙️ Step 2: Add Microsoft Teams as a Contact Point in Grafana  
1. In Grafana, go to Alerting → Contact points.
2. Click + Add contact point.
3. Name it (e.g., MS Teams Alerts).
4. From the Integration list, select Microsoft Teams.
5. Paste the Webhook URL you copied from Teams.
6. Click Test to verify the connection.
7. Click Save contact point.

### 🚨 Step 3: Use the Contact Point in Alert Rules  
1. Go to Alerting → Alert rules.
2. Edit or create a new alert rule.
3. Scroll to Configure labels and notifications.
4. Under Notifications, select the MS Teams contact point you created.
5. Save the rule.
