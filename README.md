# AWS Hub-and-Spoke Architecture with ECS and Aurora

This Terraform project deploys a production-ready hub-and-spoke network architecture on AWS, which exposes a containerized application (`k8s.gcr.io/e2e-test-images/echoserver:2.5`) to the internet.



## Architecture Overview

```
                                    Internet
                                        │
                                        ▼
                              ┌─────────────────┐
                              │   Internet GW   │
                              └────────┬────────┘
                                       │
                    ┌──────────────────┼──────────────────┐
                    │            Internet VPC             │
                    │                  │                  │
                    │  ┌─────────────┐ │                  │
                    │  │  Firewall   │ │                  │
                    │  │   Subnet    │ │                  │
                    │  │(Placeholder)│ │                  │
                    │  └─────────────┘ │                  │
                    │                  │                  │
                    │    ┌─────────────┴─────────────┐    │
                    │    │    Gateway Subnet         │    │
                    │    │   (ALB + NAT Gateway)     │    │
                    │    └─────────────┬─────────────┘    │
                    │                  │                  │
                    │    ┌─────────────┴─────────────┐    │
                    │    │       TGW Subnet          │    │
                    │    │   (TGW Attachment)        │    │
                    │    └─────────────┬─────────────┘    │
                    └──────────────────┼──────────────────┘
                                       │
                              ┌────────┴────────┐
                              │ Transit Gateway │
                              └────────┬────────┘
                                       │
                    ┌──────────────────┼──────────────────┐
                    │            Workload VPC             │
                    │                  │                  │
                    │    ┌─────────────┴─────────────┐    │
                    │    │       TGW Subnet          │    │
                    │    │   (TGW Attachment)        │    │
                    │    └─────────────┬─────────────┘    │
                    │                  │                  │
                    │    ┌─────────────┴─────────────┐    │
                    │    │       Web Subnet          │    │
                    │    │      (NLB + ALB)          │    │
                    │    └─────────────┬─────────────┘    │
                    │                  │                  │
                    │    ┌─────────────┴─────────────┐    │
                    │    │       App Subnet          │    │
                    │    │    (ECS Fargate)          │    │
                    │    └─────────────┬─────────────┘    │
                    │                  │                  │
                    │    ┌─────────────┴─────────────┐    │
                    │    │       Data Subnet         │    │
                    │    │   (Aurora PostgreSQL)     │    │
                    │    └───────────────────────────┘    │
                    └─────────────────────────────────────┘
```



## Components

### Internet VPC (Hub)
- **Internet Gateway**: Entry point from the internet
- **Firewall Subnet**: Placeholder for future firewall implementation
- **Application Load Balancer**: Public-facing load balancer
- **NAT Gateway**: Outbound internet access for private subnets
- **Transit Gateway Attachment**: Connection to TGW

### Workload VPC (Spoke)
- **Network Load Balancer**: Receives traffic from Internet VPC via TGW
- **Internal Application Load Balancer**: Routes to ECS tasks
- **ECS Fargate Cluster**: Runs the echoserver container
- **Aurora PostgreSQL**: Serverless v2 database cluster
- **Transit Gateway Attachment**: Connection to TGW
- **VPC Endpoints**: ECR, CloudWatch Logs, S3, Secrets Manager

### Transit Gateway
- Connects Internet VPC and Workload VPC
- Enables cross-VPC routing

### Architectural Trade-Offs

1. **Security Isolation vs. Cost**: Using a Transit Gateway (TGW) to separate the public-facing Internet VPC from the internal Workload VPC provides **excellent security isolation**. However, the trade-off is a significant **increase in baseline infrastructure costs** and operational complexity for a single service.


2. **Routing Flexibility vs. Latency**: Connecting a Public ALB to an internal NLB, and then to an internal ALB, allows for **advanced routing capabilities**. The trade-off is increased network hops, **higher latency for the end user**, and the cost of provisioning three separate load balancers.


3. **Centralized Egress vs. Single Point of Failure**: Routing all outbound traffic from the private subnets through a single NAT Gateway in the Internet VPC **simplifies network inspection**. The trade-off is that it creates a **single point of failure** and a potential bandwidth bottleneck for all internal applications.

### Security Flaws & Exploits
1. **Bypassed Firewall Subnet**: The design includes a firewall subnet in the Internet VPC, but traffic flows directly from the IGW to the ALB, bypassing it. Without an Intrusion Prevention System (IPS) or Deep Packet Inspection, an **attacker could successfully execute network-level exploits or port scans** that a dedicated network firewall would otherwise block.


2. **Missing Application-Layer Protection**: The Public ALB is exposed to the internet without an attached Web Application Firewall (WAF). The **application is vulnerable to Layer 7 attacks**, such as HTTP floods (DDoS) or malicious payloads like Cross-Site Scripting (XSS) and SQL injection.


3. **Unrestricted Outbound Egress**: The Workload VPC uses the TGW to route outbound traffic through the NAT Gateway. If Egress filtering is not strictly defined, the internal workloads have open access to the internet. If an attacker finds a Remote Code Execution (RCE) vulnerability in the ECS task, they could establish a reverse shell to a command-and-control server or **exfiltrate Aurora database records to an external IP**.



## 📂Project Structure
This project uses a decoupled, micro-module approach with local state and Terraform Workspaces for environment separation.
```
.
├── main.tf                    # Root orchestrator connecting all modules
├── variables.tf               # Root variable definitions
├── versions.tf                # Provider and Terraform version constraints
├── dev.tfvars                 # Development environment inputs
├── prod.tfvars                # Production environment inputs
├── outputs.tf                 # Exports the final public ALB URL
├── modules/                   # Reusable micro-modules
│   ├── vpc/                   # Dynamic VPCs, Subnets, and Route Tables
│   ├── nat-gateway/           # EIP and NAT Gateway for outbound traffic
│   ├── transit-gateway/       # TGW and cross-VPC routing attachments
│   ├── security-groups/       # Tiered ingress/egress firewall rules
│   ├── nlb/                   # Internal Network Load Balancer
│   ├── alb/                   # Application Load Balancers (Public & Internal)
│   ├── ecs/                   # Fargate Cluster, Task Def, and Service
│   ├── aurora/                # Serverless v2 DB Cluster and Subnet Groups
│   └── network-firewall/      # (Placeholder) Future DPI integration
└── .gitignore
```

## Prerequisites

1. **AWS CLI** configured with appropriate credentials
2. **Terraform** >= 1.5.0
3. **AWS Account** with sufficient permissions to create:
    - VPCs, Subnets, Route Tables
    - Internet Gateway, NAT Gateway
    - Transit Gateway
    - Network Firewall
    - Application/Network Load Balancers
    - ECS Clusters, Services, Task Definitions
    - Aurora Clusters
    - IAM Roles and Policies
    - CloudWatch Log Groups
    - Secrets Manager Secrets
    - VPC Endpoints

## 🚀Detailed Deployment Instructions

### 1. Initialize the repository
```bash
terraform init
```

### 2. Select the workspace
Ensure your state file is isolated to the correct environment.
```bash
terraform workspace new dev
```

### 3. Review the deployment plan
Validates the code and shows you the diff of AWS resources that will be created or modified
```bash
terraform plan -var-file="dev.tfvars"
```

### 4. Apply the infrastructure
Provisions the resources. Type yes when prompted.
```bash
terraform apply -var-file="dev.tfvars"
```

### 5. Access the Application

After deployment completes, get the application URL:

```bash
terraform output application_url
```

## 🧹 Teardown
To stop incurring AWS charges, you must destroy the infrastructure when testing is complete. This cleanly removes all resources in the reverse order they were created.
```bash
terraform destroy -var-file="dev.tfvars"
```

## 💰Estimated Costs

> ⚠️ **Note**: This architecture is designed for production workloads and has associated costs.

Key cost components:
- **NAT Gateway**: ~$34/month + data processing
- **Transit Gateway**: ~$36.50 + ~$73.00/month (2 VPC attachments) = ~$109.50/month.
- **ALB/NLB**: 2 ALBs + 1 NLB = ~$50.00/month combined baseline.
- **ECS Fargate**: 2 tasks (0.25 vCPU, 512MB RAM) = ~$17.00/month
- **Aurora Serverless v2**: 2 instances (Reader/Writer) at 0.5 minimum ACU = ~$105.00/month baseline.
- **VPC Endpoints**: ~$7/month per endpoint

**Estimated Monthly Total** (24/7 Uptime): ~$315.00 USD / month
(Always run terraform destroy when not actively developing!)

> **Note**: AWS Network Firewall is not deployed in this configuration (firewall subnet is a placeholder). If deployed, it would add ~$292/month per endpoint.

## Discussion Topics

### Scheduled Job Recommendations

**Requirement**: Add a schedule job to fetch the new stories from https://hacker-news.firebaseio.com every day at 5am GMT+8 and store them into the database.

Since the problem statement does not specify any requirements beyond the task, the following recommendations assume that **ease of implementation & cost** as the main driving factors.

**Recommendation**: Amazon EventBridge (as a trigger) + AWS Lambda (for computation)

1. Trigger: Amazon EventBridge configured with a cron expression to trigger the Lambda function. Since AWS uses UTC, the cron expression for 5 AM GMT+8 is cron(0 21 * * ? *) (running at 9 PM UTC the previous day).


2. Compute: An AWS Lambda function placed in the Workload VPC's private subnets. It will use the existing NAT Gateway route to fetch data from the internet securely and then execute INSERT statements into the Aurora database.

This approach **falls under the free tier** for daily execution and **requires minimal server maintenance**.

<br>

### Usage of LLM

Some LLMs (Gemini, Cline, ChatGPT) were utilized as an accelerator during this technical assessment in the following ways:

1. **Boilerplate Generation**: Used to quickly scaffold the foundational Terraform module structures, allowing for more focus on complex networking routing and security group configurations.


2. **Security Brainstorming**: Used as a sounding board to identify edge-case vulnerabilities within the multi-VPC architecture.


3. **Cross-Checking**: Outputs by 1 LLM were cross-checked by other LLMs for accuracy, edge cases, improvements & signs of hallucinations to ensure high quality of the output.

All generated configurations were **manually reviewed, refined, and tested** by human means to ensure they meet strict government requirements.

<br>

### Possible Improvements

To establish the technical foundation for future ministry initiatives, I recommend the following improvements:

1. **Implement VPC Endpoints**: Add VPC Endpoints(AWS PrivateLink) to the Workload VPC for services like ECR (to pull the container image) and CloudWatch (for logging). This keeps internal AWS traffic entirely off the public internet, enhancing compliance and reducing NAT Gateway data processing fees.


2. **Simplify the Load Balancing Layer**: Unless there is a strict requirement for Layer 4 internal routing, remove the NLB and route traffic directly from the Public ALB (in the Internet VPC) to the Internal ALB (in the Workload VPC) via the TGW. This reduces costs and latency.


3. **Enhance Security & Secrets Management**: Attach an AWS WAF(Web Application Firewall) to the Public ALB to filter malicious web traffic. Additionally, implement AWS Secrets Manager to store the Aurora database credentials securely, preventing hardcoded secrets in the infrastructure or application code.