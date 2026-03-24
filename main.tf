# ==========================================
# 1. FOUNDATION: VPCs
# ==========================================

# The Hub: Internet-facing VPC
module "internet_vpc" {
  source          = "./modules/vpc"
  vpc_name        = "internet-vpc-${var.environment}"
  cidr_block      = var.vpc_cidr_internet

  # Providing public subnets triggers the creation of an IGW and public routing
  public_subnets  = [
    cidrsubnet(var.vpc_cidr_internet, 8, 1), # e.g., 10.0.1.0/24 (Gateway AZ1)
    cidrsubnet(var.vpc_cidr_internet, 8, 2)  # e.g., 10.0.2.0/24 (Gateway AZ2)
  ]

  private_subnets = [
    cidrsubnet(var.vpc_cidr_internet, 8, 3), # e.g., 10.0.3.0/24 (Firewall AZ1)
    cidrsubnet(var.vpc_cidr_internet, 8, 4), # e.g., 10.0.4.0/24 (Firewall AZ2)
    cidrsubnet(var.vpc_cidr_internet, 8, 5), # e.g., 10.0.5.0/24 (TGW Attach AZ1)
    cidrsubnet(var.vpc_cidr_internet, 8, 6)  # e.g., 10.0.6.0/24 (TGW Attach AZ2)
  ]
}

# The Spoke: Isolated Workload VPC
module "workload_vpc" {
  source          = "./modules/vpc"
  vpc_name        = "workload-vpc-${var.environment}"
  cidr_block      = var.vpc_cidr_workload

  # Leaving public subnets empty ensures this VPC remains strictly private
  public_subnets  = []

  private_subnets = [
    cidrsubnet(var.vpc_cidr_workload, 8, 1), # Web AZ1 (NLB/ALB)
    cidrsubnet(var.vpc_cidr_workload, 8, 2), # Web AZ2 (NLB/ALB)
    cidrsubnet(var.vpc_cidr_workload, 8, 3), # App AZ1 (ECS)
    cidrsubnet(var.vpc_cidr_workload, 8, 4), # App AZ2 (ECS)
    cidrsubnet(var.vpc_cidr_workload, 8, 5), # Data AZ1 (Aurora)
    cidrsubnet(var.vpc_cidr_workload, 8, 6), # Data AZ2 (Aurora)
    cidrsubnet(var.vpc_cidr_workload, 8, 7), # TGW Attach AZ1
    cidrsubnet(var.vpc_cidr_workload, 8, 8)  # TGW Attach AZ2
  ]
}

# ==========================================
# 2. ROUTING & EGRESS: NAT & Transit Gateway
# ==========================================

# Provides outbound internet access for the Internet VPC's private subnets
module "internet_nat" {
  source                 = "./modules/nat-gateway"

  # Explicitly wiring the outputs from the Internet VPC module into the NAT module
  public_subnet_ids      = module.internet_vpc.public_subnet_ids
  private_route_table_id = module.internet_vpc.private_route_table_id
}

# module "transit_gateway" {
#   source = "./modules/transit-gateway"
#   ...
# }

# ==========================================
# 3. SECURITY & INGRESS: SGs, ALBs, NLBs
# ==========================================
# module "security_groups" { ... }
# module "internet_alb" { ... }
# module "workload_nlb" { ... }
# module "workload_alb" { ... }

# ==========================================
# 4. COMPUTE & DATA: ECS & Aurora
# ==========================================
# module "ecs_cluster" { ... }
# module "aurora_db" { ... }