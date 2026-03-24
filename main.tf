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

module "transit_gateway" {
  source   = "./modules/transit-gateway"
  tgw_name = "central-tgw-${var.environment}"

  # Internet VPC Inputs
  internet_vpc_id                 = module.internet_vpc.vpc_id
  # Extracting subnets at index 2 and 3 (the ones we allocated for TGW)
  internet_tgw_subnet_ids         = slice(module.internet_vpc.private_subnet_ids, 2, 4)
  internet_public_route_table_id  = module.internet_vpc.public_route_table_id
  internet_private_route_table_id = module.internet_vpc.private_route_table_id

  # Workload VPC Inputs
  workload_vpc_id                 = module.workload_vpc.vpc_id
  workload_vpc_cidr               = var.vpc_cidr_workload
  # Extracting subnets at index 6 and 7 (the ones we allocated for TGW)
  workload_tgw_subnet_ids         = slice(module.workload_vpc.private_subnet_ids, 6, 8)
  workload_private_route_table_id = module.workload_vpc.private_route_table_id
}

# ==========================================
# 3. SECURITY & INGRESS: SGs, ALBs, NLBs
# ==========================================
module "security_groups" {
  source            = "./modules/security-groups"
  environment       = var.environment

  internet_vpc_id   = module.internet_vpc.vpc_id
  internet_vpc_cidr = var.vpc_cidr_internet

  workload_vpc_id   = module.workload_vpc.vpc_id
  workload_vpc_cidr = var.vpc_cidr_workload
}

module "workload_nlb" {
  source             = "./modules/nlb"
  environment        = var.environment

  vpc_id             = module.workload_vpc.vpc_id
  # Extracting Web Subnets (index 0 and 1) from the private_subnet_ids list
  subnet_ids         = slice(module.workload_vpc.private_subnet_ids, 0, 2)

  security_group_ids = [module.security_groups.workload_nlb_sg_id]
}

# ==========================================
# INGRESS LAYER 1: Internet ALB (The Entrypoint)
# ==========================================
module "internet_alb" {
  source             = "./modules/alb"
  alb_name           = "internet-alb-${var.environment}"
  internal           = false # Public-facing
  vpc_id             = module.internet_vpc.vpc_id

  # Placed in the Public Subnets (Index 0 and 1)
  subnet_ids         = module.internet_vpc.public_subnet_ids
  security_group_ids = [module.security_groups.internet_alb_sg_id]
  target_port        = 80
}

# Cross-VPC Attachment: Manually register the NLB's private IPs to the Internet ALB
resource "aws_lb_target_group_attachment" "internet_alb_to_nlb" {
  # Create an attachment for every IP the NLB module outputted
  count            = length(module.workload_nlb.nlb_private_ips)
  target_group_arn = module.internet_alb.target_group_arn
  target_id        = module.workload_nlb.nlb_private_ips[count.index]
  port             = 80
}

# ==========================================
# INGRESS LAYER 2: Workload ALB (The App Gateway)
# ==========================================
module "workload_alb" {
  source             = "./modules/alb"
  alb_name           = "workload-alb-${var.environment}"
  internal           = true # Strictly internal
  vpc_id             = module.workload_vpc.vpc_id

  # Placed in the Web Subnets (Index 0 and 1) alongside the NLB
  subnet_ids         = slice(module.workload_vpc.private_subnet_ids, 0, 2)
  security_group_ids = [module.security_groups.workload_alb_sg_id]

  # Echoserver runs on port 8080
  target_port        = 8080
}

# ==========================================
# 4. COMPUTE & DATA: ECS & Aurora
# ==========================================

module "ecs_cluster" {
  source             = "./modules/ecs"
  environment        = var.environment

  # Extracting App Subnets (index 2 and 3) from the Workload VPC
  subnet_ids         = slice(module.workload_vpc.private_subnet_ids, 2, 4)
  security_group_ids = [module.security_groups.ecs_tasks_sg_id]

  # Attaching the service to the internal Workload ALB
  target_group_arn   = module.workload_alb.target_group_arn
}

module "aurora_db" {
  source             = "./modules/aurora"
  environment        = var.environment

  # Extracting Data Subnets (index 4 and 5) from the Workload VPC
  subnet_ids         = slice(module.workload_vpc.private_subnet_ids, 4, 6)
  security_group_ids = [module.security_groups.aurora_db_sg_id]
}