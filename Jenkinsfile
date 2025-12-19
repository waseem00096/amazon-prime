pipeline {
    agent any
    
    tools {
        jdk 'jdk-21'
        nodejs 'node'
    }

    environment {
        SCANNER_HOME = tool 'sonar-scanner'
        DOCKER_HUB_USER = 'waseem09' // Fixed to match your actual username
    }

    stages {
        stage('Step 1: Clean Workspace') {
            steps {
                cleanWs()
            }
        }

        stage('Step 2: Checkout Source') {
            steps {
                git branch: 'main', url: 'https://github.com/waseem00096/amazon-prime.git'
            }
        }

        stage('Step 3: SonarQube Analysis') {
            steps {
                withSonarQubeEnv('SonarQube') {
                    sh "${SCANNER_HOME}/bin/sonar-scanner -Dsonar.projectName=amazon-prime-video -Dsonar.projectKey=amazon-prime-video"
                }
            }
        }

        stage('Step 4: Quality Gate') {
            steps {
                waitForQualityGate abortPipeline: false, credentialsId: 'Sonar-token'
            }
        }

        stage('Step 5: Security Scans (FS & Dependencies)') {
            steps {
                sh "npm install"
                sh "trivy fs . > trivyfs.txt"
            }
        }

        stage('Step 6: Docker Build & Push') {
            steps {
                script {
                    withDockerRegistry(credentialsId: 'docker', toolName: 'docker') {
                        // Build using the specific tag name
                        sh "docker build -t ${DOCKER_HUB_USER}/amazon-prime:latest ."
                        sh "docker push ${DOCKER_HUB_USER}/amazon-prime:latest"
                    }
                }
            }
        }

        stage('Step 7: Docker Scout & Trivy Image Scan') {
            steps {
                script {
                    sh "docker-scout quickview ${DOCKER_HUB_USER}/amazon-prime:latest"
                    sh "trivy image ${DOCKER_HUB_USER}/amazon-prime:latest > trivyimage.txt"
                }
            }
        }

        stage('Step 8: Deploy via Docker Compose') {
            steps {
                // Better approach: Deploy the full Nginx + Node stack
                sh "docker compose down"
                sh "docker compose up -d"
            }
        }
    }
}
