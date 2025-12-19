pipeline {
    agent any
    
    tools {
        jdk 'jdk-21'
        nodejs 'node'
    }

    environment {
        SCANNER_HOME = tool 'sonar-scanner'
        DOCKER_HUB_USER = 'waseem09' 
    }

    stages {
        stage('Step 1: Clean Workspace') {
            steps { cleanWs() }
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

        stage('Step 5: Install & Scan') {
            steps {
                sh "npm install"
                sh "trivy fs . > trivyfs.txt"
            }
        }

        stage('Step 6: Docker Build & Push') {
            steps {
                script {
                    withDockerRegistry(credentialsId: 'docker', toolName: 'docker') {
                        sh "docker build -t ${DOCKER_HUB_USER}/amazon-prime:latest ."
                        sh "docker push ${DOCKER_HUB_USER}/amazon-prime:latest"
                    }
                }
            }
        }

        stage('Step 7: Image Security') {
            steps {
                sh "docker-scout quickview ${DOCKER_HUB_USER}/amazon-prime:latest"
                sh "trivy image ${DOCKER_HUB_USER}/amazon-prime:latest > trivyimage.txt"
            }
        }

        stage('Step 8: Deploy to K8s Cluster') {
            steps {
                script {
                    // This block securely uses your Kubeconfig file
                    withCredentials([file(credentialsId: 'k8s-config', variable: 'KUBECONFIG')]) {
                        sh "kubectl --kubeconfig=${KUBECONFIG} apply -f kubernetes/manifest.yml"
                        
                        // Force Kubernetes to pull the new image from Docker Hub
                        sh "kubectl --kubeconfig=${KUBECONFIG} rollout restart deployment/amazon-prime-deployment"
                    }
                }
            }
        }
    }
}
