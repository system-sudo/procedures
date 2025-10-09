# Stay informed about Jenkins build events in real time!

## 1. Send notification to MSTeams:

### Option a: Workflows

From Apps -> Select Workflows
Click Create -> In search bar type Jenkins

You will get Flows:
Get notified in Teams channel for Jenkins Events
Get notified in Teams chat for Jenkins Events

<img width="1657" height="740" alt="image" src="https://github.com/user-attachments/assets/2ee42f36-6c27-46b4-a7ea-ced6ff397dcb" />

#### Description
This workflow automatically sends a notification to a Microsoft Teams channel whenever a webhook request is received.  
To get started, generate the webhook URL using this template.

#### In Jenkins
Then, install the Office 365 Connector / Power Automate Workflows plugin in Jenkins,
<img width="1897" height="406" alt="image" src="https://github.com/user-attachments/assets/5393e79f-cc70-4569-b866-a124dec7ac01" />

and add the generated webhook URL to the job configuration for which you want to receive notifications.
<img width="1636" height="537" alt="image" src="https://github.com/user-attachments/assets/71b63695-eb76-4627-9b52-f956156a949d" />
NOTE: Do not forget to select the AdaptiveCard format option when you add the webhook.  
For setup instructions and advanced options, refer to the Jenkins plugin documentation: https://plugins.jenkins.io/Office-365-Connector/

### Option b: Jenkins Connector

Create a Channel in MSTeams  
Click Manage Channels -> Connectors  
Search for Jenkins  
<img width="766" height="932" alt="image" src="https://github.com/user-attachments/assets/ce59468f-6083-498a-84ec-be579777f10f" />

#### Description
The Jenkins connector sends notifications about build-related activities.  

#### In Jenkins
Then, install the Office 365 Connector / Power Automate Workflows plugin in Jenkins,
<img width="1897" height="406" alt="image" src="https://github.com/user-attachments/assets/5393e79f-cc70-4569-b866-a124dec7ac01" />

and add the generated webhook URL to the job configuration for which you want to receive notifications.
<img width="1615" height="647" alt="image" src="https://github.com/user-attachments/assets/be8fb2c5-2448-4d60-a8aa-68c27971ac28" />

