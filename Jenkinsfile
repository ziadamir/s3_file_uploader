pipeline {
    agent any
    environment {
        AWS_REGION  = 'us-east-1'
        GITCOMMIT="${env.GIT_COMMIT}"
    }
    stages {
        stage('Maven Build') {
            steps {        
                echo "Start Build..."
                sh 'mvn clean install'
                echo "End Build"
		    }
        }	
	
	    stage('Test') {
            steps {
                echo "Start Test..."        
			    sh 'mvn test'		
                echo "End Test"
            }
        }
    
        stage('Package') {
            steps {
                sh 'mvn package -DskipTests'
            }
        }  

        stage('Docker Build') {
            steps {
                echo "Start Docker..."
                    sh '''
                    aws ecr create-repository --repository-name s3_file_uploader --image-scanning-configuration scanOnPush=true --region us-east-1 || true
                    aws ecr get-login-password --region us-east-1 | docker login --username AWS --password-stdin 643171609537.dkr.ecr.us-east-1.amazonaws.com
                    docker build . -t  643171609537.dkr.ecr.us-east-1.amazonaws.com/s3_file_uploader:1.0.0
                    docker tag 643171609537.dkr.ecr.us-east-1.amazonaws.com/s3_file_uploader:1.0.0 643171609537.dkr.ecr.us-east-1.amazonaws.com/s3_file_uploader:1.0.0
                    ''' 
                
                echo "End Docker"
            }
        }

        stage('AWS_Deploy') {
            steps {
                echo "Start AWS_Deploy..."
                    sh '''
                    docker push 643171609537.dkr.ecr.us-east-1.amazonaws.com/s3_file_uploader:1.0.0
                    ''' 
                echo "End AWS_Deploy"
            }
        }

    }
    post {
        // Archive the jar file.
        success {
            archiveArtifacts 'target/*.jar'
        }
    }
}
