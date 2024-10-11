
Ghost-app 

Dependencies needed before proceeding:

- An IDE of your choice to pull the repo locally and proceed with the steps
- Hashicorp Terraform and AWS Toolkit extension
- Optional: AWS CLI
- An AWS account where you need to create a dummy user with AdministratorAccess Policy. Copy the access and secret key somewhere safe to use it later.
- Default output format json for the aws configure step and default region us-east-1.



Steps to deploy the Infrastructure Application to AWS and open it in your browser: 

1. Start by downloading the repository locally and change the unique values of the deploy.sh file following your credentials and choosing the putting the region default as "us-east-1".   
2. Make the script executable: chmod +x deploy.sh
3. Execute the deploy.sh file through your terminal.
4. After the "terraform apply"; a load balancer dns will be shown in your cli; this one will be the url to access the ghost web app accordingly, paste it in your browser and enjoy the "ghost app" :)

