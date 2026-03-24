# ==========================================
# 1. FOUNDATION: VPCs
# ==========================================

module "internet_vpc" {
  source          = "./modules/vpc"
  vpc_name        = "internet-vpc-${var.environment}"
  cidr_block      = var.vpc_cidr_internet
  public_subnets  = [cidrsubnet(var.vpc_cidr_internet, 8, 1), cidrsubnet(var.vpc_cidr_internet, 8, 2)] # e.g., 10.0.1.0/24, 10.0.2.0/24
  private_subnets = [cidrsubnet(var.vpc_cidr_internet, 8, 3), cidrsubnet(var.vpc_cidr_internet, 8, 4)]
}

module "workload_vpc" {
  source          = "./modules/vpc"
  vpc_name        = "workload-vpc-${var.environment}"
  cidr_block      = var.vpc_cidr_workload
  public_subnets  = [] # No public subnets in the workload VPC
  private_subnets = [
    cidrsubnet(var.vpc_cidr_workload, 8, 1), # Web 1
    cidrsubnet(var.vpc_cidr_workload, 8, 2), # Web 2
    cidrsubnet(var.vpc_cidr_workload, 8, 3), # App 1
    cidrsubnet(var.vpc_cidr_workload, 8, 4), # App 2
    cidrsubnet(var.vpc_cidr_workload, 8, 5), # Data 1
    cidrsubnet(var.vpc_cidr_workload, 8, 6)  # Data 2
  ]
}

# ==========================================
# 2. ROUTING & EGRESS: NAT & Transit Gateway
# ==========================================

module "internet_nat" {
  source                  = "./modules/nat-gateway"
  vpc_id                  = module.internet_vpc.vpc_id
  public_subnet_ids       = module.internet_vpc.public_subnet_ids
  private_route_table_ids = module.internet_vpc.private_route_table_ids
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