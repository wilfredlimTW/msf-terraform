# AWS Hub-and-Spoke Architecture with ECS and Aurora

This Terraform project deploys a production-ready hub-and-spoke network architecture on AWS, exposing the `k8s.gcr.io/e2e-test-images/echoserver:2.5` container to the internet.

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

## Project Structure

```
.
├── main.tf          # The orchestrator tying all these specific modules together
├── variables.tf     
├── versions.tf      
├── dev.tfvars       
├── prod.tfvars      
├── modules/
│   ├── vpc/                    # Creates VPC, subnets, route tables, and IGW
│   ├── nat-gateway/            # Creates Elastic IPs, NAT Gateways, and private route updates
│   ├── transit-gateway/        # Creates TGW and manages VPC attachments
│   ├── network-firewall/       # AWS Network Firewall (ready for future use)
│   ├── alb/                    # Creates ALB, Listeners, and Target Groups
│   ├── nlb/                    # Creates NLB, Listeners, and Target Groups
│   ├── ecs/                    # Creates Cluster, Task Definition (echoserver), and Service
│   ├── aurora/                 # Creates Subnet Groups, Aurora Serverless v2 Cluster/Instances
│   └── security-groups/        # Centralized SG rules mapping ports and source/destinations
└── .gitignore
```