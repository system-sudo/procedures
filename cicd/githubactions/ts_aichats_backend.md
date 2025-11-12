# Deploy Python Backend to GCP VM via GitHub Actions

## Overview
This GitHub Actions workflow automates the deployment of a Python backend application to a Google Cloud Platform (GCP) Virtual Machine (VM). It includes steps for building, testing, deploying, performing health checks, rollback on failure, and sending notifications.

## Workflow Trigger
The pipeline runs on pushes to the `staging` branch:
```yaml
on:
  push:
    branches:
      - staging
```
Update this branch to `main` or `prod` as needed.

## Environment Variables
- `GCLOUD_VERSION`: Specifies the gcloud CLI version (default: `546.0.0`).

## Prerequisites
1. A GCP VM instance with systemd services for backend and frontend.
2. GitHub repository with Python backend code.
3. Secrets configured in GitHub:
   - `GCP_SA_KEY`: Service account JSON key.
   - `GCP_PROJECT`: GCP project ID.
   - `GCP_ZONE`: GCP zone.
   - `GCP_INSTANCE_NAME`: VM instance name.
   - `GCP_SSH_USER`: SSH username for VM.
   - `TOKEN_GITHUB`: GitHub personal access token for fetching code.
   - `POWER_AUTOMATE_WEBHOOK_URL`: Webhook for notifications.

## Job Steps
### 1. **Checkout Code**
Uses `actions/checkout@v4` to pull the latest code.

### 2. **Setup Python**
Installs Python 3.11 using `actions/setup-python@v5`.

### 3. **Cache Dependencies**
Caches pip dependencies for faster builds.

### 4. **Install Dependencies**
Creates a virtual environment and installs project dependencies with `pip install -e .[dev]`.

### 5. **Run Tests (Optional)**
Executes `pytest` to run backend tests. Failures do not stop deployment.

### 6. **Authenticate to Google Cloud**
Uses `google-github-actions/auth@v2` with service account credentials.

### 7. **Setup gcloud CLI**
Installs gcloud CLI and disables auto-updates.

### 8. **Create Deployment Script**
Generates `deploy_backend.sh` which:
- Prepares rollback snapshot.
- Fetches latest code from GitHub.
- Rebuilds virtual environment.
- Restarts backend and frontend services.
- Performs health checks on `/healthz` endpoint.
- Rolls back if health check fails.

### 9. **Upload Deployment Script to VM**
Uses `gcloud compute scp` to copy script to VM.

### 10. **Run Deployment Script Remotely**
Executes script via `gcloud compute ssh` and captures exit code.

### 11. **Notify via Power Automate**
Sends deployment status (Success, Failure, or Rollback) to Microsoft Teams using Adaptive Cards.

### 12. **Cleanup Runner**
Removes temporary files and gcloud configs.

## Deployment Script Details
- **Rollback Mechanism**: If health check fails after retries, previous commit and virtual environment are restored.
- **Health Check**: Validates HTTP 200 response and JSON keys `"ok": true` and `"db": true`.

## Notifications
Adaptive Card includes:
- Deployment status.
- Repository name.
- Commit SHA.
- VM instance and zone.

## How to Use
1. Configure all required secrets in GitHub.
2. Push changes to the `staging` branch.
3. Monitor workflow logs and Teams notifications.

## Github Action Workflow
### Create Github Action Workflow file
```sh
.github/workflows/frontend.yml
```
### Paste the following:
```yaml
name: Deploy Python Backend to GCP VM (gcloud compute ssh)

on:
  push:
    branches:
      - staging  # change to 'main' or 'prod' if needed

permissions:
  contents: read

env:
  GCLOUD_VERSION: '546.0.0'

jobs:
  deploy:
    name: Build + Deploy + Notify (Backend)
    runs-on: ubuntu-latest
    environment: production

    steps:
      - uses: actions/checkout@v4

      - name: Setup Python
        uses: actions/setup-python@v5
        with:
          python-version: '3.11'

      - name: Cache pip dependencies
        uses: actions/cache@v4
        with:
          path: ~/.cache/pip
          key: ${{ runner.os }}-pip-${{ hashFiles('**/requirements*.txt', '**/pyproject.toml') }}
          restore-keys: |
            ${{ runner.os }}-pip-

      - name: Create virtual environment and install deps
        run: |
          python3 -m venv .venv
          source .venv/bin/activate
          pip install --upgrade pip
          pip install -e .[dev]

      - name: Run backend tests (optional)
        run: |
          source .venv/bin/activate
          pytest --maxfail=1 --disable-warnings -q || echo "⚠️ Tests failed, continuing..."

      - name: Authenticate to Google Cloud
        uses: google-github-actions/auth@v2
        with:
          credentials_json: ${{ secrets.GCP_SA_KEY }}

      - name: Setup gcloud CLI
        uses: google-github-actions/setup-gcloud@v1
        with:
          project_id: ${{ secrets.GCP_PROJECT }}
          version: ${{ env.GCLOUD_VERSION }}

      - run: gcloud config set component_manager/disable_update_check true
        name: Disable gcloud auto-updates

      - name: Create backend deploy script
        run: |
          cat > deploy_backend.sh <<'EOF'
          #!/bin/bash
          set -eo pipefail
          APP_DIR="/opt/aichat-backend"
          SERVICE_NAME_F="aichat-frontend.service"
          SERVICE_NAME_B="aichat-backend.service"
          HEALTH_URL="http://127.0.0.1:8000/healthz"
          ROLLBACK_DIR=".rollback"

          echo "Starting backend deployment on $(hostname) as $(whoami)"
          cd "$APP_DIR"

          echo "Preparing rollback snapshot..."
          mkdir -p "$ROLLBACK_DIR"
          git rev-parse HEAD > "$ROLLBACK_DIR/previous_commit" || true
          cp -r .venv "$ROLLBACK_DIR/" 2>/dev/null || true

          echo "Fetching latest code..."
          sudo git fetch https://${TOKEN_GITHUB}@github.com/TRST-Score/aichat-backend.git staging
          sudo git reset --hard FETCH_HEAD

          echo "Rebuilding virtual environment..."
          python3 -m venv .venv
          source .venv/bin/activate
          pip install --upgrade pip
          pip install -e .[dev]

          echo "Restarting backend service..."
          systemctl restart "$SERVICE_NAME_F"
          systemctl restart "$SERVICE_NAME_B"
          sleep 20

          echo "Performing health check on $HEALTH_URL..."

          MAX_RETRIES=6
          RETRY_DELAY=5
          SUCCESS=false
          
          for i in $(seq 1 $MAX_RETRIES); do
            echo "Attempt $i of $MAX_RETRIES..."
            HTTP_STATUS=$(curl -s -o health_response.json -w "%{http_code}" "$HEALTH_URL" || echo "000")
            if [ "$HTTP_STATUS" -eq 200 ]; then
              if grep -q '"ok":true' health_response.json && grep -q '"db":true' health_response.json; then
                SUCCESS=true
                break
              fi
            fi
            echo "Health check failed (HTTP $HTTP_STATUS). Retrying in $RETRY_DELAY seconds..."
            sleep $RETRY_DELAY
          done
          
          if [ "$SUCCESS" = true ]; then
            echo "✅ Health check passed successfully."
            rm -f health_response.json
          else
            echo "❌ Health check failed after $MAX_RETRIES attempts. Rolling back..."
            PREV=$(cat "$ROLLBACK_DIR/previous_commit")
            git reset --hard "$PREV"
            if [ -d "$ROLLBACK_DIR/.venv" ]; then
              rm -rf .venv
              cp -r "$ROLLBACK_DIR/.venv" .venv
            fi
            systemctl restart "$SERVICE_NAME_F"
            systemctl restart "$SERVICE_NAME_B" || echo "⚠️ Failed to restart $SERVICE_NAME after rollback"
            echo "Rollback complete."
            exit 2
          fi
          
          echo "✅ Backend deployment succeeded and health check passed."
          exit 0
          EOF
          chmod +x deploy_backend.sh

      - name: Upload deploy script to VM
        run: |
          gcloud compute scp deploy_backend.sh \
            "${{ secrets.GCP_SSH_USER }}@${{ secrets.GCP_INSTANCE_NAME }}:~/deploy_backend.sh" \
            --project="${{ secrets.GCP_PROJECT }}" \
            --zone="${{ secrets.GCP_ZONE }}" --quiet

      - name: Run deploy script remotely and capture exit code
        id: run_deploy
        run: |
          gcloud compute ssh "${{ secrets.GCP_SSH_USER }}@${{ secrets.GCP_INSTANCE_NAME }}" \
            --project="${{ secrets.GCP_PROJECT }}" \
            --zone="${{ secrets.GCP_ZONE }}" \
            --command="sudo bash -lc 'TOKEN_GITHUB=\"${{ secrets.TOKEN_GITHUB }}\" bash ~/deploy_backend.sh; echo \$? > ~/deploy_exit_code'" \
            --quiet || true

          gcloud compute scp "${{ secrets.GCP_SSH_USER }}@${{ secrets.GCP_INSTANCE_NAME }}:~/deploy_exit_code" ./deploy_exit_code \
            --project="${{ secrets.GCP_PROJECT }}" \
            --zone="${{ secrets.GCP_ZONE }}" --quiet

          DEP_EXIT=$(cat ./deploy_exit_code)
          echo "deploy_exit=$DEP_EXIT" >> $GITHUB_OUTPUT

      - name: Notify Power Automate
        if: always()
        run: |
          STATUS="❌ Backend Deployment Failed"
          COLOR="Attention"
          if [ "${{ steps.run_deploy.outputs.deploy_exit }}" = "0" ]; then
            STATUS="✅ Backend Deployment Successful"
            COLOR="Good"
          elif [ "${{ steps.run_deploy.outputs.deploy_exit }}" = "2" ]; then
            STATUS="⚠️ Backend Deployment Rolled Back"
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
          rm -f deploy_backend.sh ./deploy_exit_code
          rm -rf ~/.config/gcloud .venv
```
---
**Note**: Ensure VM has proper permissions and systemd services configured for smooth deployment.
