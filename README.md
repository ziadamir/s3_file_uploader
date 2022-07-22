# S3FileUploader

S3FileUploader application consists of a Maven project using Spring Boot with an embedded tomcat server to host an web interface for uploading files to and S3 bucket

# File and folder organization

```
+---src
├── Jenkinsfile
├── README.md
├── dockerfile
├── mvnw
├── mvnw.cmd
├── pom.xml
├── src
│   ├── main
│   │   ├── java
│   │   │   └── net
│   │   │       └── codejava
│   │   │           └── aws
│   │   │               ├── MainController.java
│   │   │               ├── S3FileUploadApplication.java
│   │   │               └── S3Util.java
│   │   └── resources
│   │       ├── application.properties
│   │       ├── static
│   │       └── templates
│   │           ├── message.html
│   │           └── upload.html
│   └── test
│       └── java
│           └── net
│               └── codejava
│                   └── aws
│                       └── S3FileUploadApplicationTests.java
├── target
│   ├── classes
│   │   ├── application.properties
│   │   ├── net
│   │   │   └── codejava
│   │   │       └── aws
│   │   │           ├── MainController.class
│   │   │           ├── S3FileUploadApplication.class
│   │   │           └── S3Util.class
│   │   └── templates
│   │       ├── message.html
│   │       └── upload.html
│   └── test-classes
│       └── net
│           └── codejava
│               └── aws
│                   └── S3FileUploadApplicationTests.class
└── terraform
    └── main.tf
```

# Requirements
### 1)  An AWS account

### 2)  Jenkins server, preferably running on Amazon Linux 2, with IAM permissions to read and write from S3, ECR, ECS, CloudWatch Logs, EC2/VPC, and IAM. Jenkins server must have basic pipeline plugins installed

### 3)  The following must be installed on the Jenkins server or on local for testing:
* Java 11
* Docker
* Maven
* Git
* awscliv2
* terraform

# Deploying locally (must have aws access keys and region configured on local system and permission to create, list and put in s3 buckets):
### 1) Build artifact with Maven:
* Clone git repo: git clone https://github.com/ziadamir/s3_file_uploader.git
* cd s3_file_uploader/
* Run: mvn clean install

### 2) Build Docker Image
* Start Docker if not already running
* Run the following:
```bash
# Build docker image
$ docker build . -t s3_file_uploader:1.0

# List images to verify that image was created correctly
$ docker images --filter reference=s3_file_uploader
```
### 2) Run Docker Container
```bash
$ docker run -t -i -p 8080:8080 s3_file_uploader:1.0
```
Open localhost:8080 in browser

### 3) Testing the application

* Select choose file and upload a test file, enter a file description, and click the Submit button

* If you have the correct AWS credentials and region configured, the application will create an s3 bucket called "s3-upload-input-bucket" and upload the file.

# Deploying to AWS ECS Fargate

### 1) Build and push Docker image
```bash
# Build docker image
$ docker build . -t  <aws_account_id>.dkr.ecr.<aws_region>.amazonaws.com/s3_file_uploader:1.0
```

```bash
# Create ECR repository
$ aws ecr create-repository --repository-name s3_file_uploader --image-scanning-configuration scanOnPush=true --region <aws_region>
```

```bash
# Tag image with repo uri
$ docker tag <aws_account_id>.dkr.ecr.<aws_region>.amazonaws.com/s3_file_uploader:1.0 <aws_account_id>.dkr.ecr.<aws_region>.amazonaws.com/s3_file_uploader:1.0
```

```bash
# Login to ECR
$ aws ecr get-login-password --region <aws_region> | docker login --username AWS --password-stdin <aws_account_id>.dkr.ecr.<aws_region>.amazonaws.com
```

```bash
# Push image to ecr
$ docker push <aws_account_id>.dkr.ecr.<aws_region>.amazonaws.com/s3_file_uploader:1.0
```
### 2) Create ECS infrastructure
* main.tf will create a VPC, 2 public subnets and routing, IAM role and policy for ECS task execution, ECS task definition, ECS cluster, ECS service, and CloudWatch log group

```bash
# Change to terraform directory
$ cd terraform
```

```bash
# Initialize terraform
$ terraform init
```
```bash
# Build infrastructure
$ terraform apply
```
*  Enter values for the following parameters when prompted:
    * aws_account_id
    * aws_region
    * env (i.e dev, used for tagging)
    * vpc_cidr
    * subnet_a_cidr
    * subnet_b_cidr
    * image_tag (must match artifact version in pom.xml and dockerfile)
    * process (default: s3_file_uploader)
* Open AWS ECS console > Cluster > select cluster name > select service > click task tab > click task container ID > under Network, copy public IP > open<public_ip>:8080 in browser

# Deploying to AWS ECS via Jenkins

* Deployment via Jenkins requires github webhook and access token to be created
* You can fork this repository and create your own webhook and access token and then configure them with Jenkins
* Create new pipeline project
* Check off GitHub project and enter Project URL
* Check off this project is paramterized > string parameter > and configure the following Names and Values:
    * aws_account_id
    * aws_region
    * env (i.e dev, used for tagging)
    * vpc_cidr
    * subnet_a_cidr
    * subnet_b_cidr
    * image_tag (must match artifact version in pom.xml and dockerfile)
    * process (default: s3_file_uploader)
* Check off GitHub hook trigger for GITScm polling (this will poll the repo for new pushes)
* Under Pipeline select Pipeline script from SCM (this will pull the jenkins file from the repo)
* Configure git credentials using git username as username and access token as password
* Enter branch to build: "*/main"
* Enter script path: Jenkinsfile
* Apply and Save
* Pushing a change to the main branch will now trigger the Jenkins pipeline
