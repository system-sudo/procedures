```sh
name: DevSecOps Pipeline

on:
  push:
    branches:
      - main
    paths-ignore:
      - kubernetes/**
  pull_request:
    branches:
      - main

jobs:
  # Unit testing
  test:
    name: Unit testing
    runs-on: ubuntu-latest
    steps:
      - name: checkout code
        uses: actions/checkout@v4

      - name: Setup Node.js
        uses: actions/setup-node@v4
        with:
          node-version: 20
      
      - name: Cache npm
        uses: actions/cache@v3
        with:
          path: ~/.npm
          key: ${{ runner.os }}-npm-${{ hashFiles('package-lock.json') }}
          restore-keys: |
            ${{ runner.os }}-npm-

      - name: Install dependencies
        run: npm ci

      - name: Run testsx
        run: npm test 

  # Node.js Build & Test

  build-and-test:
    name: Build & Test
    runs-on: ubuntu-latest
    needs: test

    steps:
      - name: Checkout code
        uses: actions/checkout@v4

      - name: Setup Node.js
        uses: actions/setup-node@v4
        with:
          node-version: 20

      - name: Cache npm
        uses: actions/cache@v3
        with:
          path: ~/.npm
          key: ${{ runner.os }}-npm-${{ hashFiles('package-lock.json') }}
          restore-keys: |
            ${{ runner.os }}-npm-

      - name: Install dependencies
        run: npm ci

      - name: Run lint
        run: npm run lint || true  

      - name: Build project
        run: npm run build


  # Dependency Vulnerability Scan
 
  dependency-scan:
    name: Dependency Security Scan
    runs-on: ubuntu-latest
    needs: build-and-test

    steps:
      - name: Checkout code
        uses: actions/checkout@v4

      - name: Setup Node.js
        uses: actions/setup-node@v4
        with:
          node-version: 20

      - name: Cache npm
        uses: actions/cache@v3
        with:
          path: ~/.npm
          key: ${{ runner.os }}-npm-${{ hashFiles('package-lock.json') }}
          restore-keys: |
            ${{ runner.os }}-npm-

      - name: Install dependencies
        run: npm ci

      - name: Audit dependencies
        run: npm audit --audit-level=high || true

      - name: Run Snyk Dependency Scan
        uses: snyk/actions/node@master
        continue-on-error: true
        env:
          SNYK_TOKEN: ${{ secrets.SNYK_TOKEN }}
        with:
          command: test
          args: --severity-threshold=medium


  # Docker Build & Scan
 
  docker-build-and-scan:
    name: Docker Build & Security Scan
    runs-on: ubuntu-latest
    needs: dependency-scan
    outputs:
      image_tag: ${{ steps.vars.outputs.TAG }}

    steps:
      - name: Checkout code
        uses: actions/checkout@v4
      
      - name: Set image tag output
        id: vars
        run: echo "TAG=$(echo ${{ github.sha }} | cut -c1-7)" >> $GITHUB_OUTPUT
    
      - name: Set up Docker Buildx
        uses: docker/setup-buildx-action@v3

      - name: Log in to Docker Hub
        uses: docker/login-action@v3
        with:
          username: ${{ secrets.DOCKER_USERNAME }}
          password: ${{ secrets.DOCKER_PASSWORD }}

      - name: Build Docker image
        run: docker buildx build --cache-from type=gha --cache-to type=gha,mode=max -t streamgen-ai:${{ steps.vars.outputs.TAG }} --load .

      - name: Save docker artifact
        run: docker save streamgen-ai:${{ steps.vars.outputs.TAG }} -o streamgen-ai.tar

      - name: Uploading artifact
        uses: actions/upload-artifact@v4
        with:
          name: streamgen-ai
          path: streamgen-ai.tar

      - name: Scan Docker image
        uses: aquasecurity/trivy-action@master
        with:
          image-ref: streamgen-ai:${{ steps.vars.outputs.TAG }}
          format: table
          exit-code: 0
          severity: CRITICAL,HIGH

      - name: Snyk Container Scan
        uses: snyk/actions/docker@master
        env:
          SNYK_TOKEN: ${{ secrets.SNYK_TOKEN }}
        with:
          image: streamgen-ai:${{ steps.vars.outputs.TAG }}
          args: --severity-threshold=medium

  # OWASP ZAP Baseline DAST Scan

  zap-dast:
    name: OWASP ZAP DAST Scan
    runs-on: ubuntu-latest
    needs: docker-build-and-scan

    steps:
      - name: Checkout code
        uses: actions/checkout@v4

      - name: Download Docker image
        uses: actions/download-artifact@v4
        with:
          name: streamgen-ai

      - name: Load Docker image
        run: docker load -i streamgen-ai.tar

      - name: Start application
        run: |
          docker run -d --name app -p 3000:80 streamgen-ai:${{ needs.docker-build-and-scan.outputs.image_tag }}
          echo "Waiting for app..."
          for i in {1..60}; do
            if curl -sf http://localhost:3000 >/dev/null 2>&1; then
              echo "App is ready!"
              break
            fi
            echo "Attempt $i: Application not ready, retrying..."
            sleep 2
          done

      - name: Run OWASP ZAP Baseline Scan
        uses: zaproxy/action-baseline@v0.14.0
        with:
          target: "http://localhost:3000"
          artifact_name: "zap_report"
          allow_issue_writing: false
          cmd_options: -J report_json.json -w report_md.md -r report_html.html --autooff

  # Deploy to Docker Hub
  
  deploy:
    name: Deploy to Docker Hub
    runs-on: ubuntu-latest
    needs: [docker-build-and-scan,zap-dast]
    if: github.ref == 'refs/heads/main'

    steps:
      - name: Checkout code
        uses: actions/checkout@v4
      
      - name: Download artifact
        uses: actions/download-artifact@v4
        with:
          name: streamgen-ai
        
      - name: load docker
        run: docker load -i streamgen-ai.tar

      - name: Log in to Docker Hub
        uses: docker/login-action@v3
        with:
          username: ${{ secrets.DOCKER_USERNAME }}
          password: ${{ secrets.DOCKER_PASSWORD }}

      - name: Push Docker image
        run: |
          docker tag streamgen-ai:${{ needs.docker-build-and-scan.outputs.image_tag }} ${{ secrets.DOCKER_USERNAME }}/streamgen-ai:${{ needs.docker-build-and-scan.outputs.image_tag }}
          docker push ${{ secrets.DOCKER_USERNAME }}/streamgen-ai:${{ needs.docker-build-and-scan.outputs.image_tag }}
  
  update-k8s:
    name: Update Kubernetes Deployment
    runs-on: ubuntu-latest
    needs: [deploy,docker-build-and-scan]
    if: github.ref == 'refs/heads/main'
    steps:
      - name: Checkout code
        uses: actions/checkout@v4
        with:
          token: ${{ secrets.TOKEN }}
      
      - name: Setup Git config
        run: |
          git config user.name "paripuranam"
          git config user.email "paripuranam333@gmail.com"
      
      - name: Update Kubernetes deployment file
        env:
          NEW_IMAGE: paripuranam/streamgen-ai:${{ needs.docker-build-and-scan.outputs.image_tag }}
        run: |
          echo "Updating deployment to image: $NEW_IMAGE"

          sed -i "s|image: .*|image: ${NEW_IMAGE}|g" kubernetes/deployment.yaml
          
          echo "Updated deployment file:"
          grep "image:" kubernetes/deployment.yaml
      
      - name: Commit and push changes
        run: |
          git add kubernetes/deployment.yaml
          git commit -m "Update Kubernetes deployment with new image tag: ${{ needs.docker-build-and-scan.outputs.image_tag }}" || echo "No changes to commit"
          git push
```
