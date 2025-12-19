pipeline {
    agent any

    environment {
        // Replace with your actual Docker Hub ID
        DOCKER_HUB_USER = 'waseem09'
        IMAGE_NAME      = 'amazon-prime'
        IMAGE_TAG       = "latest" // Or use "${env.BUILD_NUMBER}" for versioning
    }

    stages {
        stage('Step 1: Cleanup Workspace') {
            steps {
                echo 'Cleaning up old build artifacts...'
                cleanWs() 
            }
        }

        stage('Step 2: Checkout Source') {
            steps {
                // Jenkins will automatically pull the repo configured in the Job
                echo 'Pulling latest code from GitHub...'
                checkout scm
            }
        }

        stage('Step 3: Build Docker Image') {
            steps {
                echo 'Building the Amazon Prime Docker Image...'
                script {
                    // Build the specific service from your compose file
                    sh "docker compose build node-app"
                }
            }
        }

        stage('Step 4: Push to Docker Hub') {
            steps {
                echo 'Pushing image to Docker Hub...'
                script {
                    // Ensure you have a 'docker-hub-credentials' ID set up in Jenkins
                    withCredentials([usernamePassword(credentialsId: 'docker-hub-credentials', passwordVariable: 'DOCKER_PASS', usernameVariable: 'DOCKER_USER')]) {
                        sh "echo \$DOCKER_PASS | docker login -u \$DOCKER_USER --password-stdin"
                        sh "docker tag amazon-prime-video-kubernetes-node-app ${DOCKER_HUB_USER}/${IMAGE_NAME}:${IMAGE_TAG}"
                        sh "docker push ${DOCKER_HUB_USER}/${IMAGE_NAME}:${IMAGE_TAG}"
                    }
                }
            }
        }

        stage('Step 5: Deploy with Docker Compose') {
            steps {
                echo 'Restarting containers with the new image...'
                sh "docker compose down"
                sh "docker compose up -d"
            }
        }
    }

    post {
        always {
            echo 'Pipeline finished. Cleaning up local unused images...'
            sh "docker image prune -f"
        }
        success {
            echo 'Deployment successful! Access your app at http://172.16.18.178'
        }
    }
}
