## How to configure and run a simple GitHub Actions pipeline
This guide walks you from zero → a working CI pipeline in GitHub Actions.

### 1) Prerequisites
* A GitHub account.
* Basic repository (code or a sample project).

### 2) Quick overview of concepts
* Workflow: a YAML file placed at .github/workflows/*.yml in your repo. It declares events (push, pull_request, manual), jobs, and steps.
* Runner: the virtual machine (GitHub-hosted or self-hosted) that executes your steps.
* Action: reusable building block (checkout action, setup-node, etc.).
* Secrets: encrypted values stored in the repo/org used in workflows via secrets.*. Never hard-code secrets in repo files.

### 3) Create a basic workflow: ci.yml
Create a folder .github/workflows in the repo where you want to run the pipeline and add a file ci.yml.
It runs on push and pull_request events and supports manual runs.
```sh
.github/workflows/ci.yml
```
```sh
name: Python CI

on:
  push:
    branches: [ main ]
  pull_request:
    branches: [ main ]
  workflow_dispatch:   # allows manual runs from GitHub UI

jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - name: Set up Python
        uses: actions/setup-python@v4
        with:
          python-version: '3.11'
      - name: Install
        run: python -m pip install -r requirements.txt
      - name: Run tests
        run: pytest
```
### 4) Commit and push to trigger the pipeline
When you push, GitHub will automatically kick off the workflow (because on: push).
* Push / Pull Request: pushes & PRs matching your branch rules will run automatically.
* Manual: go to the repo → Actions tab → select the workflow → Run workflow (if workflow_dispatch is enabled).
* Schedule: add schedule in on: with cron if you want periodic runs.

### 5) Viewing results and logs
Repo → Actions → click the workflow run.

Click a job (e.g., build) → expand steps to see their logs.

If a step failed, logs show the failing command and output. Use the Re-run jobs button to retry (full or failed jobs).

### 6) How to configure GitHub Actions secrets
1. Repository-level secrets
2. Go to your repository on GitHub.
3. Click Settings → Secrets and variables → Actions → New repository secret.

Enter Name (e.g., DOCKERHUB_TOKEN) and Value (the secret). Click Add secret.
Use secret in workflow as ${{ secrets.MY_SECRET }}
#### Using secrets in workflows

Reference secrets via the secrets context. Example:
Store DOCKERHUB_USERNAME and DOCKERHUB_TOKEN in repo Secrets.
```sh
- name: Log in to Docker Hub
  uses: docker/login-action@v3
  with:
    username: ${{ secrets.DOCKERHUB_USERNAME }}
    password: ${{ secrets.DOCKERHUB_TOKEN }}

- name: Build and push
  uses: docker/build-push-action@v5
  with:
    push: true
    tags: youruser/yourimage:latest
```
Use short-lived credentials where possible:
Prefer OIDC or cloud provider short-lived tokens rather than long-lived static secrets. (GitHub Actions supports OIDC to get cloud tokens.)
