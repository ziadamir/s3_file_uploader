pipeline {
    agent any
    environment {
        AWS_REGION="${aws_region}"
    }
    stages {
        stage('Maven Build') {
            steps {        
                echo "Start Build"
                sh 'mvn clean install'
                echo "End Build"
		    }
        }	
	
	    stage('Test') {
            steps {
                echo "Start Test"        
			    sh 'mvn test'		
                echo "End Test"
            }
        }
    
        stage('Package') {
            steps {
                echo "Start Package"
                sh 'mvn package -DskipTests'
                echo "End Package"
            }
        }  

        stage('Docker Build') {
            steps {
                echo "Start Docker"
                    sh '''
                    aws ecr create-repository --repository-name s3_file_uploader --image-scanning-configuration scanOnPush=true --region us-east-1 || true
                    aws ecr get-login-password --region us-east-1 | docker login --username AWS --password-stdin 643171609537.dkr.ecr.us-east-1.amazonaws.com
                    docker build . -t  643171609537.dkr.ecr.us-east-1.amazonaws.com/s3_file_uploader:latest
                    docker tag 643171609537.dkr.ecr.us-east-1.amazonaws.com/s3_file_uploader:latest 643171609537.dkr.ecr.us-east-1.amazonaws.com/s3_file_uploader:latest
                    ''' 
                
                echo "End Docker"
            }
        }

        stage('AWS Deploy') {
            steps {
                echo "Start AWS Deploy"
                    sh 'docker push 643171609537.dkr.ecr.us-east-1.amazonaws.com/s3_file_uploader:latest'
                echo "End AWS_Deploy"
            }
        }

        stage('Terraform Build') {
            steps {
                echo "Start Terraform Build"
                    sh '''
                    export TF_VAR_aws_account_id=$aws_account_id
                    export TF_VAR_aws_region=$aws_region 
                    export TF_VAR_vpc_cidr=$vpc_cidr
                    export TF_VAR_subnet_a_cidr=$subnet_a_cidr
                    export TF_VAR_subnet_b_cidr=$subnet_b_cidr
                    export TF_VAR_image_tag=$image_tag
                    export TF_VAR_process=$process
                    cd terraform/
                    terraform init -input=false
                    terraform plan -out=tfplan -input=false
                    terraform apply -input=false tfplan
                    '''
                echo "End Terraform Build"
            }
        }
    }
    post {
        // Archive the jar file.
        success {
            archiveArtifacts 'target/*.jar'
            archiveArtifacts 'terraform/tfplan*'
        }
    }
}
