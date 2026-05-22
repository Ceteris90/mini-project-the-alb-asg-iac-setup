Resilient ALB + ASG Architecture Setup
This repository serves as a blueprint for deploying a highly available, scalable, and secure infrastructure on AWS using Infrastructure as Code (IaC). By configuring an internet-facing Application Load Balancer (ALB) to distribute traffic across an Auto Scaling Group (ASG) in a custom multi-AZ VPC, this project ensures high fault tolerance and a clean separation of networking concerns.

🏗 Project Architecture
The architecture adheres strictly to AWS production-ready best practices:

Network Isolation: A custom VPC with public subnets hosting the ALB, and private subnets hosting the compute instances.

Elastic Scaling: An Auto Scaling Group managing Nginx web instances across multiple Availability Zones.

Least-Privilege Security: Security groups are tiered so that the web servers in private subnets only accept HTTP traffic originating from the ALB.

Automated Bootstrapping: A launch template equipped with a user-data bash script to dynamically provision Nginx and inject runtime metadata.

📂 Directory Layout
Plaintext
.
├── scripts/
│   └── user_data.sh        # Provisioning script to install and configure Nginx
├── main.tf                 # Core VPC networking (Subnets, IGW, NAT Gateways)            # Least-privilege Security Groups and IAM configurations
├── compute.tf              # Launch Template, Auto Scaling Group, and Target Group       # Application Load Balancer, Listeners, and Rules
├── variables.tf            # Input configuration variables and defaults
├── outputs.tf              # Architecture deployment outputs (ALB DNS, VPC ID)
└── README.md               # Project documentation and deployment guide
🚀 Getting Started
1. Prerequisites
Terraform CLI installed (v1.5.0+).

AWS CLI configured locally with administrative permissions.

Active AWS Account.

2. Initialization
Navigate to the root project directory where your configuration files are located and initialize the Terraform provider and backend:

Bash
terraform init
3. Deployment Flow
Always validate your syntax and run an execution plan to verify what resources will be created, modified, or destroyed:

Bash
terraform validate
terraform plan
If the execution plan looks correct, apply the changes to provision the infrastructure:

Bash
terraform apply -auto-approve
⏱ Note: The initial deployment may take 3 to 5 minutes while AWS provisions the multi-AZ NAT Gateways and runs initial health validation checks on the web nodes.

🛠 Features
Multi-AZ Resiliency: Redundant NAT Gateways and subnet layers distributed symmetrically across distinct Availability Zones to eliminate single points of failure.

Dynamic Traffic Distribution: The ALB tracks instance health via custom HTTP endpoints, instantly rerouting traffic if a single node fails.

Stateless Compute: Instances can scale out (up to 4) or scale in (down to 2) dynamically based on performance parameters or scheduling demands.

Dynamic Metadata Landing Page: The bootstrap script builds a tailored index page capturing the active Instance ID and current Availability Zone at initialization.

📝 Best Practices
State Verification: Inspect the final alb_dns_name output variable string to test traffic balancing via an external browser.

State Cleanliness: Always run terraform fmt to maintain style formatting standards across configuration files before committing changes.

Destruction Lifecycle: To ensure you do not incur ongoing AWS infrastructure charges for this setup, run the teardown workflow when finished:

Bash
terraform destroy -auto-approve
Maintained by: [Jonas Kwame Nyador]
