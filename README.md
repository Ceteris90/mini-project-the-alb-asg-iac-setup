# Resilient ALB + ASG Architecture on AWS (Terraform)

This repository is a Terraform blueprint for deploying a highly available, scalable, and secure web architecture on AWS. It provisions a custom multi-AZ VPC, an internet-facing Application Load Balancer (ALB), and an Auto Scaling Group (ASG) of Nginx web servers running in private subnets — following AWS best practices for network isolation and least-privilege access.

## Architecture Overview

```
<img width="1380" height="752" alt="Gemini_Generated_Image_ovl4kyovl4kyovl4" src="https://github.com/user-attachments/assets/2de41b0c-9489-40a4-a889-32c78c609f58" />
```

- **Public subnets** host the ALB and the NAT Gateways (one per AZ for true multi-AZ resilience).
- **Private subnets** host the EC2 instances managed by the Auto Scaling Group — they have no public IPs and reach the internet only through the NAT Gateways.
- **Security Groups** are tiered: the ALB accepts HTTP traffic from anywhere, while the EC2 instances accept HTTP traffic only from the ALB's security group.

## Features

- **Multi-AZ resiliency** — Public/private subnets and NAT Gateways are distributed across multiple Availability Zones, eliminating single points of failure.
- **Dynamic traffic distribution** — The ALB performs health checks against the target group and reroutes traffic away from unhealthy instances automatically.
- **Elastic, stateless compute** — The ASG scales between a configurable min and max instance count, replacing unhealthy nodes automatically.
- **Automated bootstrapping** — A launch template user-data script installs and starts Nginx, and serves a landing page displaying the instance's hostname (handy for confirming load balancing is working).
- **Least-privilege networking** — Web servers are never exposed directly to the internet; all inbound traffic must pass through the ALB.
- **Dynamic AMI lookup** — The launch template always uses the latest Amazon Linux 2023 AMI via a data source, instead of a hardcoded AMI ID.

## Repository Structure

```
.
├── main.tf                              # Root module — wires up the child module
└── modules/
    └── computer_storage/
        ├── main.tf                      # VPC, subnets, IGW, NAT gateways, route tables
        ├── compute_and_alb.tf           # Security groups, ALB, target group, listener,
        │                                #   launch template, and Auto Scaling Group
        ├── variables.tf                 # Input variables and defaults
        └── output.tf                    # Output values (VPC ID, subnet IDs, ALB DNS name)
```

## Prerequisites

- [Terraform](https://developer.hashicorp.com/terraform/downloads) v1.5.0 or later
- [AWS CLI](https://aws.amazon.com/cli/) installed and configured with credentials that have permission to create VPC, EC2, Auto Scaling, and ELB resources
- An active AWS account

## Configuration

All inputs are defined in `modules/computer_storage/variables.tf` and can be overridden via a `terraform.tfvars` file or `-var` flags.

| Variable               | Type         | Default                              | Description                                       |
|-------------------------|--------------|---------------------------------------|----------------------------------------------------|
| `aws_region`            | string       | `us-east-1`                          | AWS region to deploy resources into                |
| `vpc_cidr`              | string       | `10.0.0.0/16`                        | Base CIDR block for the VPC                        |
| `public_subnet_cidrs`   | list(string) | `["10.0.1.0/24", "10.0.2.0/24"]`     | CIDR blocks for public subnets (requires at least 2)|
| `private_subnet_cidrs`  | list(string) | `["10.0.11.0/24", "10.0.12.0/24"]`   | CIDR blocks for private subnets (requires at least 2)|
| `instance_type`         | string       | `t3.micro`                           | EC2 instance type for the web servers               |
| `asg_min_size`          | number       | `2`                                   | Minimum number of instances in the ASG              |
| `asg_max_size`          | number       | `4`                                   | Maximum number of instances in the ASG              |
| `asg_desired_capacity`  | number       | `2`                                   | Desired number of instances in the ASG              |

## Usage

### 1. Initialize Terraform

```bash
terraform init
```

### 2. Review the execution plan

```bash
terraform validate
terraform plan
```

### 3. Apply the configuration

```bash
terraform apply -auto-approve
```

> ⏱ **Note:** Initial deployment can take 3–5 minutes while AWS provisions the multi-AZ NAT Gateways and runs initial health checks on the web instances.

### 4. Test the deployment

After `terraform apply` completes, grab the `alb_dns_name` output and open it in a browser or curl it a few times — you should see the hostname change as the ALB distributes traffic across instances:

```bash
terraform output alb_dns_name
curl http://<alb_dns_name>
```

## Outputs

| Output               | Description                                                        |
|-----------------------|---------------------------------------------------------------------|
| `vpc_id`              | The ID of the provisioned VPC                                       |
| `public_subnet_ids`   | IDs of the public subnets                                            |
| `private_subnet_ids`  | IDs of the private subnets                                           |
| `alb_dns_name`        | Public DNS name of the ALB — use this to test the deployment        |

## Best Practices Applied

- **State verification** — Use the `alb_dns_name` output to confirm traffic is being balanced correctly.
- **Formatting** — Run `terraform fmt` before committing to keep configuration style consistent.
- **Clean teardown** — Destroy all resources when you're done to avoid ongoing AWS charges:

```bash
terraform destroy -auto-approve
```

## Notes & Possible Improvements

- The `provider "aws"` block is currently defined inside the child module; for larger projects it's generally cleaner to define providers in the root module and pass configuration down.
- HTTPS/TLS termination on the ALB (via ACM + an HTTPS listener) is not yet configured — currently only HTTP (port 80) is supported.
- No remote backend (e.g., S3 + DynamoDB) is configured for Terraform state; consider adding one for team use.

## Maintained by

Jonas Kwame Nyador
