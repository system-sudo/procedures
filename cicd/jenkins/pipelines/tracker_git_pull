pipeline {
    agent any

    environment {
        WORKDIR = '/var/www/html/staging/tracker-frontend-v2-new'
        GIT_CREDENTIALS_ID = 'github-cred'
    }

    triggers {
        githubPush() // Trigger pipeline on GitHub push
    }

    stages {
        stage('Old Build Backup') {
            steps {
                dir("${WORKDIR}") {
                    script {
                        def timestamp = new Date().format("ddMMyyyy-HHmmss")
                        sh "zip -r build-backup-${timestamp}.zip build"
                    }
                }
            }
        }
        stage('Update Local Server with Latest Code') {
            steps {
                withCredentials([usernamePassword(credentialsId: env.GIT_CREDENTIALS_ID, usernameVariable: 'GIT_USERNAME', passwordVariable: 'GIT_PASSWORD')]) {
                    sh """
                        cd ${WORKDIR}
                        git pull https://${GIT_USERNAME}:${GIT_PASSWORD}@github.com/ramkumarsq1/tracker-frontend-v2-new.git staging
                    """
                }
            }
        }

        stage('Git Checkout') {
            steps {
                dir("${WORKDIR}") {
                    sh "git checkout staging"
                }
            }
        }

        stage('Npm run build') {
            steps {
                dir("${WORKDIR}") {
                    // Optional: ensure dependencies are installed-sh "sudo npm install" 
                    sh "sudo npm run build"
                }
            }
        }

        stage('Copy .htaccess file') {
            steps {
                dir("${WORKDIR}") {
                    sh "cp -r .htaccess ${WORKDIR}/build/"
                }
            }
        }
    }
}
