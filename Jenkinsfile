pipeline {
    agent any
    environment {
        AWS_REGION="${aws_region}"
    }
    stages {
        stage('Maven Compile') {
            steps {        
                echo "Start Build"
                sh 'mvn clean compile'
                echo "End Build"
		    }
        }	
	
	    stage('Maven Test') {
            steps {
                echo "Start Test"        
			    sh 'mvn test'		
                echo "End Test"
            }
        }
    
        stage('Maven Package') {
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
                    aws ecr create-repository --repository-name ${process} --image-scanning-configuration scanOnPush=true --region ${aws_region} || true
                    docker rmi ${aws_account_id}.dkr.ecr.${aws_region}.amazonaws.com/${process}:${image_tag}
                    docker build . -t  ${aws_account_id}.dkr.ecr.${aws_region}.amazonaws.com/${process}:${image_tag}
                    docker tag ${aws_account_id}.dkr.ecr.${aws_region}.amazonaws.com/${process}:${image_tag} ${aws_account_id}.dkr.ecr.${aws_region}.amazonaws.com/${process}:${image_tag}
                    ''' 
                echo "End Docker"
            }
        }

        stage('AWS Deploy') {
            steps {
                echo "Start AWS Deploy"
                    sh '''
                    aws ecr get-login-password --region ${aws_region} | docker login --username AWS --password-stdin ${aws_account_id}.dkr.ecr.${aws_region}.amazonaws.com
                    docker push ${aws_account_id}.dkr.ecr.${aws_region}.amazonaws.com/${process}:${image_tag}
                    '''
                echo "End AWS_Deploy"
            }
        }

        stage('Terraform Build') {
            steps {
                echo "Start Terraform Build"
                    sh '''
                    export TF_VAR_aws_account_id=$aws_account_id
                    export TF_VAR_aws_region=$aws_region
                    export TF_VAR_env=$env
                    export TF_VAR_vpc_cidr=$vpc_cidr
                    export TF_VAR_subnet_a_cidr=$subnet_a_cidr
                    export TF_VAR_subnet_b_cidr=$subnet_b_cidr
                    export TF_VAR_image_tag=$image_tag
                    export TF_VAR_process=$process
                    cd terraform/
                    terraform init -input=false
                    terraform plan -out=tfplan.out -input=false
                    terraform apply -auto-approve -input=false tfplan.out
                    '''
                echo "End Terraform Build"
            }
        }
    }
    post {
        // Archive the jar file.
        success {
            archiveArtifacts 'target/*.jar'
            archiveArtifacts 'terraform/tfplan.out'
        }
    }
}
