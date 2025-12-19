pipeline {
    agent any
    
    tools {
        jdk 'jdk-21'
        nodejs 'node'
    }

    environment {
        SCANNER_HOME = tool 'sonar-scanner'
        DOCKER_HUB_USER = 'waseem09'
        SONAR_SCANNER_OPTS = "-Xmx1024m"
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
                    sh "${SCANNER_HOME}/bin/sonar-scanner -Dsonar.projectName=amazon-prime -Dsonar.projectKey=amazon-prime-video"
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

      stage('Step 7: Docker Scout & Trivy Image Scan') {
        steps {
            script {
            // Use the credentials you already set up in Jenkins
                withCredentials([usernamePassword(credentialsId: 'docker', passwordVariable: 'DOCKER_PASS', usernameVariable: 'DOCKER_USER')]) {
                // 1. Authenticate Docker Scout
                sh "echo \$DOCKER_PASS | docker login -u \$DOCKER_USER --password-stdin"
                
                // 2. Run the scans using the absolute path we set up earlier
                sh "/usr/local/lib/docker/cli-plugins/docker-scout quickview ${DOCKER_HUB_USER}/amazon-prime:latest"
                sh "trivy image ${DOCKER_HUB_USER}/amazon-prime:latest > trivyimage.txt"
            }
        }
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
