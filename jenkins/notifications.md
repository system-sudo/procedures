# Stay informed about Jenkins build events in real time!

## 1. Send notification to MSTeams:

### Option a: Workflows

From Apps -> Select Workflows
Click Create -> In search bar type Jenkins

You will get Flows:
Get notified in Teams channel for Jenkins Events
Get notified in Teams chat for Jenkins Events

#### Description
This workflow automatically sends a notification to a Microsoft Teams channel whenever a webhook request is received.
To get started, generate the webhook URL using this template.

#### In Jenkins
Then, install the Office 365 Connector / Power Automate Workflows plugin in Jenkins,
and add the generated webhook URL to the job configuration for which you want to receive notifications.
Do not forget to select the AdaptiveCard format option when you add the webhook.
For setup instructions and advanced options, refer to the Jenkins plugin documentation: https://plugins.jenkins.io/Office-365-Connector/
