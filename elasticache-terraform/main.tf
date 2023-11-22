provider "aws" {
  region = "us-west-2"
}

module "this" {
  source  = "cloudposse/label/null"
  # Cloud Posse recommends pinning every module to a specific version
  # version = "0.25.0"
}

module "vpc" {
  source = "cloudposse/vpc/aws"
  # Cloud Posse recommends pinning every module to a specific version
  # version = "x.x.x"
  ipv4_primary_cidr_block = "10.0.0.0/16"

  context = module.this.context
}

module "subnets" {
  source = "cloudposse/dynamic-subnets/aws"
  # Cloud Posse recommends pinning every module to a specific version
  # version = "x.x.x"

  availability_zones   = []
  vpc_id               = module.vpc.vpc_id
  igw_id               = [module.vpc.igw_id]
  nat_gateway_enabled  = true
  nat_instance_enabled = false

  context = module.this.context
}

module "redis" {
  source = "../terraform-aws-elasticache-redis"
  # Cloud Posse recommends pinning every module to a specific version
  # version = "x.x.x"
  description = "testing-elasticache"
  replication_group_id = "testing-elasticache-rg"

  availability_zones         = []
  vpc_id                     = module.vpc.vpc_id
  allowed_security_group_ids = [module.vpc.vpc_default_security_group_id]
  subnets                    = module.subnets.private_subnet_ids
  cluster_size               = 2
  instance_type              = "cache.t3.micro"
  apply_immediately          = true
  automatic_failover_enabled = false

  parameter = [
    {
      name  = "notify-keyspace-events"
      value = "lK"
    }
  ]

  context = module.this.context
}