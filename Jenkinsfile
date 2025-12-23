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

        stage('Step 8: Deploy to K8s Cluster') {
            steps {
                script {
                    withCredentials([file(credentialsId: 'k8s-config', variable: 'KUBECONFIG')]) {
                        sh "kubectl --kubeconfig=\$KUBECONFIG delete service amazon-prime-service --all-namespaces --insecure-skip-tls-verify || true"
                        sh "sleep 5"
                        sh "kubectl --kubeconfig=\$KUBECONFIG apply -f kubernetes/manifest.yml -n jenkins --insecure-skip-tls-verify"
                        sh "kubectl --kubeconfig=\$KUBECONFIG rollout restart deployment/amazon-prime-deployment -n jenkins --insecure-skip-tls-verify"
                    }
                }
            }
        }

        // NEW MONITORING STAGE
        stage('Step 9: Setup & Verify Monitoring') {
            steps {
                script {
                    withCredentials([file(credentialsId: 'k8s-config', variable: 'KUBECONFIG')]) {
                        echo "Installing Prometheus and Grafana Stack..."
                        
                        // 1. Add Helm Repo
                        sh "helm repo add prometheus-community https://prometheus-community.github.io/helm-charts"
                        sh "helm repo update"

                        // 2. Install/Upgrade the Stack (Idempotent)
                        // We set Grafana to NodePort 32001 so you can access it at http://<Master-IP>:32001
                        sh """
                        helm upgrade --install kube-stack prometheus-community/kube-prometheus-stack \
                            --namespace monitoring \
                            --create-namespace \
                            --kubeconfig=\$KUBECONFIG \
                            --set grafana.service.type=NodePort \
                            --set grafana.service.nodePort=32001
                        """
                        
                        // 3. Verify the monitoring pods are coming up
                        sh "kubectl --kubeconfig=\$KUBECONFIG get pods -n monitoring"
                    }
                }
            }
        }
    }
}
