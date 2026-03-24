# 1. Database Subnet Group
resource "aws_db_subnet_group" "this" {
  name       = "aurora-subnet-group-${var.environment}"
  subnet_ids = var.subnet_ids

  tags = {
    Name = "aurora-subnet-group-${var.environment}"
  }
}

# 2. Aurora PostgreSQL Cluster (Serverless v2)
resource "aws_rds_cluster" "this" {
  cluster_identifier          = "aurora-cluster-${var.environment}"
  engine                      = "aurora-postgresql"
  engine_mode                 = "provisioned"
  engine_version              = "15.4" # Or your preferred compatible version
  database_name               = var.database_name
  master_username             = var.master_username

  # AWS will automatically generate and manage the password in Secrets Manager
  manage_master_user_password = true

  db_subnet_group_name        = aws_db_subnet_group.this.name
  vpc_security_group_ids      = var.security_group_ids

  skip_final_snapshot         = var.environment == "dev" ? true : false
  storage_encrypted           = true

  # Serverless v2 Scaling Configuration (measured in ACUs - Aurora Capacity Units)
  serverlessv2_scaling_configuration {
    min_capacity = 0.5 # ~1 GB RAM
    max_capacity = 4.0 # ~8 GB RAM
  }

  tags = {
    Name = "aurora-cluster-${var.environment}"
  }
}

# 3. Aurora Cluster Instances (Serverless v2 class)
resource "aws_rds_cluster_instance" "this" {
  count                = 2 # Provisions one writer and one reader for HA
  identifier           = "aurora-instance-${var.environment}-${count.index + 1}"
  cluster_identifier   = aws_rds_cluster.this.id
  instance_class       = "db.serverless"
  engine               = aws_rds_cluster.this.engine
  engine_version       = aws_rds_cluster.this.engine_version
  db_subnet_group_name = aws_db_subnet_group.this.name
}