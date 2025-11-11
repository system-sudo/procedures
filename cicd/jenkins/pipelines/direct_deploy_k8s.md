```sh
pipeline {
    agent any

    environment {
        dockerImageName = 'systemtesting48/sq1'
        registryCredential = 'docker'
        dockerImage = ''
    }

    stages {
        stage('Skip Auto-Commits') {
            steps {
            script {
                def lastCommitMessage = sh(script: "git log -1 --pretty=%B", returnStdout: true).trim()
                if (lastCommitMessage.contains("[skip ci]")) {
                    echo "Auto-commit detected. Skipping build."
                    currentBuild.result = 'SUCCESS'
                    error("Stopping pipeline due to auto-commit.")
                }
            }
        }
    }

        stage('Cloning Git') {
            steps {
                git(
                    url: 'https://github.com/system-sudo/sq1projects.git',
                    branch: 'main',
                    credentialsId: 'github'
                )
            }
        }

        stage('Build Image') {
            steps {
                script {
                    dockerImage = docker.build(dockerImageName)
                }
            }
        }

        stage('Push Image') {
            steps {
                script {
                    docker.withRegistry('https://registry.hub.docker.com', registryCredential) {
                        dockerImage.push("$BUILD_NUMBER")
                        dockerImage.push('latest')
                    }
                }
            }
        }

        stage('Update Deployment File') {
    environment {
        GIT_REPO_NAME = "sq1projects"
        GIT_USER_NAME = "system-sudo"
    }
    steps {
        script {
            def newTag = "${dockerImageName}:${BUILD_NUMBER}"

            // Update the image tag in the YAML file
            sh """
                sed -i 's|^\\s*image: .*|        image: ${newTag}|' deploymentservice.yaml
            """


            // Git commit and push the changes
            withCredentials([string(credentialsId: 'github_token', variable: 'GITHUB_TOKEN')]) {
                sh """
                    git config user.email "systemtesting48@gmail.com"
                    git config user.name "system-sudo"
                    git add deploymentservice.yaml
                    git commit -m "[skip ci] Update deployment image to version ${BUILD_NUMBER}" || echo "No changes to commit"
                    git push https://${GITHUB_TOKEN}@github.com/${GIT_USER_NAME}/${GIT_REPO_NAME} HEAD:main
                """
            }
        }
    }
}

            
        stage('Deploy to Kubernetes') {
    steps {
        withCredentials([file(credentialsId: 'kubecred', variable: 'KUBECONFIG')]) {
            sh '''
                echo "Using kubeconfig at: $KUBECONFIG"
                kubectl config get-contexts
                kubectl get pods
                kubectl apply -f deploymentservice.yaml
            '''
        }
    }
}

        
    }
}
```
