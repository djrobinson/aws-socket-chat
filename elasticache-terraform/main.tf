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
  name = "socket-auction-vpc"
  # Cloud Posse recommends pinning every module to a specific version
  # version = "x.x.x"
  ipv4_primary_cidr_block = "10.0.0.0/16"

  context = module.this.context
}

################# Below is new stuff that should enable lambdas to access ###########

resource "aws_security_group" "ws_lambda_sg" {
  name        = "ws_lambda_sg"
  description = "Allow TLS inbound traffic"
  vpc_id      = module.vpc.vpc_id

  ingress {
    description      = "REDIS PORT from LAMBDA"
    from_port        = 6379
    to_port          = 6379
    protocol         = "tcp"
    security_groups      = [module.vpc.vpc_default_security_group_id]
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  tags = {
    Name = "ws_lambda_sg"
  }
}

resource "aws_ssm_parameter" "lambda_sg_ssm" {
  name        = "/lambda/sg/AWS_SG"
  type = "String"
  description = "SG for lambda"
  value       = "${aws_security_group.ws_lambda_sg.id}"
}




resource "aws_iam_role" "socket_api_role" {
  name = "SocketAuctionApiRole"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        "Action": [
            "execute-api:Invoke",
            "execute-api:ManageConnections"
        ],
        "Resource": "arn:aws:execute-api:*:*:*"
      }
    ]
  })
}

resource "aws_iam_policy" "vpc_access_policy" {
  name        = "vpc_access_policy"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        "Action": [
            "logs:CreateLogGroup",
            "logs:CreateLogStream",
            "logs:PutLogEvents",
            "ec2:CreateNetworkInterface",
            "ec2:DescribeNetworkInterfaces",
            "ec2:DeleteNetworkInterface",
            "ec2:AssignPrivateIpAddresses",
            "ec2:UnassignPrivateIpAddresses"
        ],
        "Resource": "*"
      }
    ]
  })
}


resource "aws_iam_role_policy_attachment" "attachment" {
  role       = aws_iam_role.socket_api_role.name
  policy_arn = aws_iam_policy.vpc_access_policy.arn
}

resource "aws_ssm_parameter" "socket_role_arn" {
  type = "String"
  name        = "/lambda/role/socket"
  description = "subnets that lambdas must attach to"
  value       = "${aws_iam_role.socket_api_role.arn}"
}


resource "aws_ssm_parameter" "private_subnets" {
  for_each    = toset(module.subnets.private_subnet_ids)
  type = "String"
  name        = "/lambda/subnet/VPC_SUBNET${index(module.subnets.private_subnet_ids, each.value) + 1}"
  description = "subnets that lambdas must attach to"
  value       = "${each.value}"
}

################# Above is new stuff that should enable lambdas to access ###########


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


resource "aws_ssm_parameter" "lambda_redis_cluster_ssm" {
  name        = "/elasticache/redis/REDIS_CLUSTER_ENDPOINT"
  type = "String"
  description = "SG for lambda"
  value       = "${aws_security_group.ws_lambda_sg.id}"
}