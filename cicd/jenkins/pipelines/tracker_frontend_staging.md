### 🚀 Pipeline Summary
#### This Jenkins pipeline automates the process of:

* Pulling the latest code from a GitHub repository.
* Verifying the Node.js and pnpm setup.
* Installing dependencies and building the project using pnpm.
* Copying the .htaccess file into the build output directory.

It runs on a Jenkins agent labeled staging and is triggered automatically by GitHub push events.

```sh
pipeline {
    agent { label 'staging' }

    environment {
        WORKDIR = '/var/www/html/staging/tracker-vite'
        GIT_CREDENTIALS_ID = 'github-cred'
    }

    triggers {
        githubPush() // Trigger pipeline on GitHub push
    }

    stages {
    stage('Update Local Server with Latest Code') {
            steps {
                withCredentials([usernamePassword(credentialsId: env.GIT_CREDENTIALS_ID, usernameVariable: 'GIT_USERNAME', passwordVariable: 'GIT_PASSWORD')]) {
                    sh """
                        cd ${WORKDIR}
                        git config --global --add safe.directory /var/www/html/staging/tracker-vite
                        git checkout UAT
                        git pull https://${GIT_USERNAME}:${GIT_PASSWORD}@github.com/SQ1Security/tracker-frontend.git UAT
                    """
                }
            }
        }
        stage('Check Node') {
    steps {
        sh '''
            echo "Node path: $(which node)"
            node -v
            pnpm -v
        '''
    }
}

    stage('pnpm Install & Build') {
    steps {
        dir("${WORKDIR}") {
            sh '''
                # Install dependencies
                pnpm install

                pnpm run build
            '''
        }
    }
}

        stage('Copy .htaccess file') {
            steps {
                dir("${WORKDIR}") {
                    sh "cp -r .htaccess ${WORKDIR}/dist/"
                }
            }
        }

    }
}
```
