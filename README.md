# Terraform
Infrastructure as Code (IaC) principles using Terraform with AWS provider
## AWS CLI commands output

**The following are CLI commands that outputs a description of the components in my infructure formatted by table:**

- VPCs : aws ec2 describe-vpcs --output table

- RouteTables: aws ec2 describe-route-tables --output table

- InternetGateways: aws ec2 describe-internet-gateways --output table

- SecurityGroups : aws ec2 describe-security-groups --output table

- ec2 Instances: aws ec2 describe-instances --output table


To run the main.tf terraform configuration file:
- navigate to the directory where main.tf is located
- run "terraform init" to prepare the working directory for the following commands
- run "terraform apply" to apply the infrastructure configurations 

### Link to demo video: https://youtu.be/oc22P_3-qmk
### submitted by: Haniehsadat Gholamhosseini 
