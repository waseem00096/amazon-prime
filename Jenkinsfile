pipeline{
    agent any
    tools{
        jdk 'jdk-21'
        nodejs 'node'
    }
    environment {
        SCANNER_HOME=tool 'sonar-scanner'
    }
    stages {
        stage('clean workspace'){
            steps{
                cleanWs()
            }
        }
        stage('Checkout from Git'){
            steps{
                git branch: 'main', url: 'https://github.com/waseem00096/amazon-prime.git'
            }
        }
        stage("Sonarqube Analysis "){
            steps{
                withSonarQubeEnv('SonarQube') {
                    sh ''' $SCANNER_HOME/bin/sonar-scanner -Dsonar.projectName=amazon-prime-video \
                    -Dsonar.projectKey=amazon-prime-video '''
                }
            }
        }
        stage("quality gate"){
           steps {
                script {
                    waitForQualityGate abortPipeline: false, credentialsId: 'Sonar-token' 
                }
            } 
        }
        stage('Install Dependencies') {
            steps {
                sh "npm install"
            }
        }        
        stage('TRIVY FS SCAN') {
            steps {
                sh "trivy fs . > trivyfs.txt"
            }
        }
        stage("Docker Build & Push"){
            steps{
                script{
                   withDockerRegistry(credentialsId: 'docker', toolName: 'docker'){   
                       sh "docker build -t amazon-prime ."
                       sh "docker tag amazon-prime-video waseem09/amazon-prime:latest "
                       sh "docker push waseem09/amazon-prime:latest "
                    }
                }
            }
        }
		stage('Docker Scout Image') {
            steps {
                script{
                   withDockerRegistry(credentialsId: 'docker', toolName: 'docker'){
                       sh 'docker-scout quickview waseem09/amazon-prime:latest'
                       sh 'docker-scout cves waseem09/amazon-prime:latest'
                       sh 'docker-scout recommendations waseem09/amazon-prime:latest'
                   }
                }
            }
        }

        stage("TRIVY-docker-images"){
            steps{
                sh "trivy image waseem09/amazon-prime:latest > trivyimage.txt" 
            }
        }
        stage('App Deploy to Docker container'){
            steps{
                sh 'docker run -d --name amazon-prime -p 3000:3000 waseem09/amazon-prime:latest'
            }
        }

    }
   
