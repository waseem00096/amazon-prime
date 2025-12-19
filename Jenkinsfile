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
            // Trivy is very fast, so a 2-minute timeout is more than enough
            timeout(time: 2, unit: 'MINUTES') {
                // Scan the image and save full details to a text file
                sh "trivy image ${DOCKER_HUB_USER}/amazon-prime:latest > trivyimage.txt"
                
                // Also print a summary to the Jenkins console for quick viewing
                sh "trivy image --severity HIGH,CRITICAL ${DOCKER_HUB_USER}/amazon-prime:latest"
            }
        }
    }
}

        stage('Step 8: Deploy to K8s Cluster') {
    steps {
        script {
            withCredentials([file(credentialsId: 'k8s-config', variable: 'KUBECONFIG')]) {
                // Add the --insecure-skip-tls-verify flag to bypass the PEM parsing error
                sh "kubectl --kubeconfig=\$KUBECONFIG apply -f kubernetes/manifest.yml --insecure-skip-tls-verify"
                sh "kubectl --kubeconfig=\$KUBECONFIG rollout restart deployment/amazon-prime-deployment --insecure-skip-tls-verify"
            }
        }
    }
}
    }
}
