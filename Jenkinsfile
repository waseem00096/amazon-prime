pipeline {
    agent any
    
    tools {
        jdk 'jdk-21'
        nodejs 'node'
        // Add terraform to tools if configured in Global Tool Configuration
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

        stage('Step 7: Trivy Image Scan') {
            steps {
                script {
                    timeout(time: 5, unit: 'MINUTES') {
                        def scanStatus = sh(
                            script: "trivy image --skip-version-check ${DOCKER_HUB_USER}/amazon-prime:latest",
                            returnStatus: true
                        )
                        echo "Trivy scan finished with status: ${scanStatus}"
                    }
                }
            }
        }

        // NEW: Infrastructure as Code stage replacing manual Helm commands
        stage('Step 8: Infrastructure & Monitoring (Terraform)') {
            steps {
                script {
                    withCredentials([string(credentialsId: 'k8s-config-text', variable: 'KUBE_BASE64')]) {
                        // Decode kubeconfig for Terraform to use
                        sh "mkdir -p ~/.kube && echo '${KUBE_BASE64}' | base64 --decode > ~/.kube/config"
                        
                        dir('terraform') {
                            sh 'terraform init'
                            sh 'terraform apply -auto-approve'
                        }
                    }
                }
            }
        }

        stage('Step 9: App Deployment (K8s)') {
            steps {
                script {
                    withCredentials([string(credentialsId: 'k8s-config-text', variable: 'KUBE_BASE64')]) {
                        sh "echo '${KUBE_BASE64}' | base64 --decode > kubeconfig.yaml"
                        sh "kubectl --kubeconfig=kubeconfig.yaml apply -f kubernetes/manifest.yml -n jenkins --insecure-skip-tls-verify"
                        sh "kubectl --kubeconfig=kubeconfig.yaml rollout restart deployment/amazon-prime-deployment -n jenkins --insecure-skip-tls-verify"
                    }
                }
            }
        }
    }
}
