# Deploy Next.js to GCP VM via GitHub Actions

### Overview
This GitHub Actions workflow automates the deployment of a **Next.js application** to a **Google Cloud Platform (GCP) Virtual Machine** using `gcloud compute ssh`. It includes build caching, rollback mechanisms, health checks, and notifications via Power Automate.

### Prerequisites
- A GCP VM instance with:
  - Node.js installed
  - Systemd service configured for your app (e.g., `aichat-frontend.service`)
- GitHub repository with Next.js project
- Service account key with sufficient permissions for Compute Engine
- Installed `gcloud` CLI on the runner (handled by the workflow)

### Secrets Configuration
Add the following secrets in your GitHub repository:
- `GCP_SA_KEY`: JSON key for GCP service account
- `GCP_PROJECT`: GCP project ID eg: trst-score
- `GCP_ZONE`: Zone of the VM instance eg: asia-south1-b
- `GCP_INSTANCE_NAME`: Name of the VM instance eg: aichat-trstscore-vm
- `GCP_SSH_USER`: SSH username for VM eg: root
- `TOKEN_GITHUB`: GitHub token for fetching code on VM eg: Github Personal Access Token
- `HEALTH_URL`: URL for health check after deployment eg: https://aichats.trstscore.com/
- `POWER_AUTOMATE_WEBHOOK_URL`: Webhook for notifications eg : https://default99305083070045c68ab219cb66e550.2c.environment.api.powerplatform.com:443/powerautomate/automations/direct/workflows/f412e8adc95b4957958293cb3b9e2a22/triggers/manual/paths/invoke?api-version=1&sp=%2Ftriggers%2Fmanual%2Frun&sv=1.0&sig=fGQPSuZxBMcj1fWeGsqdQgviSpmnGQ0uyf6YWrzvZBM
- `EXTERNAL_API_BASE_URL`: External API base URL for build eg : https://api.trstscore.com/

## Workflow Explanation
### Trigger
- Runs on `push` to the `staging` branch.

### Steps
1. **Checkout Code**: Uses `actions/checkout@v4`.
2. **Setup Node.js**: Installs Node.js v20 and caches npm dependencies.
3. **Cache Next.js Build Output**: Speeds up builds by caching `.next/cache`.
4. **Install & Build**: Runs `npm ci` and `npm run build` locally.
5. **Authenticate to Google Cloud**: Uses `google-github-actions/auth@v2`.
6. **Setup gcloud CLI**: Installs specified version and disables auto-updates.
7. **Create Deploy Script**: Generates `deploy.sh` for remote execution.
8. **Upload Deploy Script**: Copies script to VM using `gcloud compute scp`.
9. **Run Deploy Script**: Executes script remotely and captures exit code.
10. **Notify Power Automate**: Sends deployment status to Microsoft Teams.
11. **Cleanup**: Removes temporary files and clears caches.

### Deployment Script Details
The script performs:
- Rollback snapshot creation
- Fetch latest code from GitHub
- Install dependencies and rebuild
- Restart systemd service
- Health check and rollback if needed

### Rollback Mechanism
If health check fails:
- Previous commit and `.next` build are restored
- Service is restarted
- Exit code `2` indicates rollback

### Notifications
Power Automate webhook sends an Adaptive Card with:
- Deployment status (Success, Failed, Rolled Back)
- Repository, commit, instance, and zone details

### Cleanup
Removes deploy script, exit code file, and clears gcloud and npm caches.

---
### Example Command to Trigger Workflow
Push changes to `staging` branch:
```bash
git push origin staging
```

## Github Action Workflow
### Create Github Action Workflow file
```sh
.github/workflows/frontend.yml
```
### Paste the following:
```sh
name: Deploy Next.js to GCP VM (gcloud compute ssh)

on:
  push:
    branches:
      - staging

permissions:
  contents: read

env:
  GCLOUD_VERSION: '546.0.0'

jobs:
  deploy:
    name: Build + Deploy + Notify
    runs-on: ubuntu-latest
    environment: production

    steps:
      - uses: actions/checkout@v4

      - name: Setup Node.js
        uses: actions/setup-node@v4
        with:
          node-version: 20
          cache: 'npm'

      - name: Cache Next.js build output
        uses: actions/cache@v4
        with:
          path: |
            .next/cache
            node_modules/.cache
          key: ${{ runner.os }}-nextjs-${{ hashFiles('package-lock.json') }}
          restore-keys: |
            ${{ runner.os }}-nextjs-

      - name: Install deps and build locally
        run: |
          npm ci
          npm run build
        env:
          EXTERNAL_API_BASE_URL: ${{ secrets.EXTERNAL_API_BASE_URL }}

      - name: Authenticate to Google Cloud
        uses: google-github-actions/auth@v2
        with:
          credentials_json: ${{ secrets.GCP_SA_KEY }}

      - name: Setup gcloud CLI
        uses: google-github-actions/setup-gcloud@v1
        with:
          project_id: ${{ secrets.GCP_PROJECT }}
          version: ${{ env.GCLOUD_VERSION }}
          install_components: 'beta'

      - run: gcloud config set component_manager/disable_update_check true
        name: Disable gcloud auto-updates

      - name: Create deploy script
        run: |
          cat > deploy.sh <<'EOF'
          #!/bin/bash
          set -eo pipefail
          APP_DIR="/opt/aichat-frontend"
          SERVICE_NAME_F="aichat-frontend.service"
          SERVICE_NAME_B="aichat-backend.service"
          HEALTH_URL="${HEALTH_URL}"
          ROLLBACK_DIR=".rollback"

          echo "Starting deployment on $(hostname) as $(whoami)"
          cd "$APP_DIR"

          echo "Preparing rollback snapshot..."
          mkdir -p "$ROLLBACK_DIR"
          git rev-parse HEAD > "$ROLLBACK_DIR/previous_commit" || true
          cp -r .next "$ROLLBACK_DIR/" 2>/dev/null || true

          echo "Fetching latest code..."
          # Ensure this uses SSH remote or injected token
          sudo git fetch https://${TOKEN_GITHUB}@github.com/TRST-Score/aichat-frontend.git staging
          sudo git reset --hard FETCH_HEAD


          echo "Installing dependencies..."
          npm ci
          echo "Building..."
          npm run build

          echo "Restarting service..."
          systemctl restart "$SERVICE_NAME_F"
          systemctl restart "$SERVICE_NAME_B"
          sleep 10

          if [ -n "$HEALTH_URL" ]; then
            STATUS=$(curl -s -o /dev/null -w "%{http_code}" "$HEALTH_URL" || echo "000")
            if [ "$STATUS" -ne 200 ]; then
              echo "Health check failed ($STATUS). Rolling back..."
              PREV=$(cat "$ROLLBACK_DIR/previous_commit")
              git reset --hard "$PREV"
              if [ -d "$ROLLBACK_DIR/.next" ]; then
                rm -rf .next
                cp -r "$ROLLBACK_DIR/.next" .next
              fi
              systemctl restart "$SERVICE_NAME_F"
              systemctl restart "$SERVICE_NAME_B"
              echo "Rollback complete."
              exit 2
            fi
          fi

          echo "Deployment succeeded."
          exit 0
          EOF
          chmod +x deploy.sh

      - name: Upload deploy script to VM
        run: |
          gcloud compute scp deploy.sh \
            "${{ secrets.GCP_SSH_USER }}@${{ secrets.GCP_INSTANCE_NAME }}:~/deploy.sh" \
            --project="${{ secrets.GCP_PROJECT }}" \
            --zone="${{ secrets.GCP_ZONE }}" --quiet

      - name: Run deploy script remotely and capture exit code
        id: run_deploy
        run: |
          gcloud compute ssh "${{ secrets.GCP_SSH_USER }}@${{ secrets.GCP_INSTANCE_NAME }}" \
            --project="${{ secrets.GCP_PROJECT }}" \
            --zone="${{ secrets.GCP_ZONE }}" \
            --command="sudo bash -lc 'TOKEN_GITHUB=\"${{ secrets.TOKEN_GITHUB }}\" HEALTH_URL=\"${{ secrets.HEALTH_URL }}\" bash ~/deploy.sh; echo \$? > ~/deploy_exit_code'" \
            --quiet || true

          gcloud compute scp "${{ secrets.GCP_SSH_USER }}@${{ secrets.GCP_INSTANCE_NAME }}:~/deploy_exit_code" ./deploy_exit_code \
            --project="${{ secrets.GCP_PROJECT }}" \
            --zone="${{ secrets.GCP_ZONE }}" --quiet

          DEP_EXIT=$(cat ./deploy_exit_code)
          echo "deploy_exit=$DEP_EXIT" >> $GITHUB_OUTPUT

      - name: Notify Power Automate
        if: always()
        run: |
          STATUS="❌ Deployment Failed"
          COLOR="Attention"
          if [ "${{ steps.run_deploy.outputs.deploy_exit }}" = "0" ]; then
            STATUS="✅ Deployment Successful"
            COLOR="Good"
          elif [ "${{ steps.run_deploy.outputs.deploy_exit }}" = "2" ]; then
            STATUS="⚠️ Deployment Rolled Back"
            COLOR="Warning"
          fi

          curl -X POST -H "Content-Type: application/json" \
            -d "{
              \"attachments\": [
                {
                  \"contentType\": \"application/vnd.microsoft.card.adaptive\",
                  \"content\": {
                    \"type\": \"AdaptiveCard\",
                    \"version\": \"1.5\",
                    \"body\": [
                      { \"type\": \"TextBlock\", \"text\": \"$STATUS\", \"size\": \"Large\", \"weight\": \"Bolder\", \"color\": \"$COLOR\" },
                      { \"type\": \"TextBlock\", \"text\": \"Repository: ${{ github.repository }}\", \"wrap\": true },
                      { \"type\": \"TextBlock\", \"text\": \"Commit: ${{ github.sha }}\", \"wrap\": true },
                      { \"type\": \"TextBlock\", \"text\": \"Instance: ${{ secrets.GCP_INSTANCE_NAME }}\", \"wrap\": true },
                      { \"type\": \"TextBlock\", \"text\": \"Zone: ${{ secrets.GCP_ZONE }}\", \"wrap\": true }
                    ]
                  }
                }
              ]
            }" \
            '${{ secrets.POWER_AUTOMATE_WEBHOOK_URL }}'

      - name: Cleanup runner
        if: always()
        run: |
          rm -f deploy.sh ./deploy_exit_code
          rm -rf ~/.config/gcloud
          npm cache clean --force || true
```
