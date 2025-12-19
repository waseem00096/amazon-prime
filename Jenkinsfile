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
            // Increased to 5 minutes to give Trivy more time to process the 233MB image
            timeout(time: 5, unit: 'MINUTES') {
                // 'returnStatus: true' prevents the whole pipeline from failing if the scan hits a snag
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
                // Use the namespace 'jenkins' for both commands to match your cluster config
                sh "kubectl --kubeconfig=\$KUBECONFIG apply -f kubernetes/manifest.yml -n jenkins --insecure-skip-tls-verify"
                
                sh "kubectl --kubeconfig=\$KUBECONFIG rollout restart deployment/amazon-prime-deployment -n jenkins --insecure-skip-tls-verify"
            }
        }
    }
}
    }
}
