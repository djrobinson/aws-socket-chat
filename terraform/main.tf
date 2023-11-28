provider "aws" {
  region = "us-west-2"
}

module "this" {
  source  = "cloudposse/label/null"
  version = "0.25.0"
}

module "vpc" {
  source                  = "cloudposse/vpc/aws"
  name                    = "socket-auction-vpc"
  version                 = "2.1.1"
  ipv4_primary_cidr_block = "10.0.0.0/16"

  context = module.this.context
}

################# Resources below enable lambda access to elasticache, ssm vars used in serverless.yml ###########

# What should ingress be in this case?
resource "aws_security_group" "ws_lambda_sg" {
  name        = "ws_lambda_sg"
  description = "Allow TLS inbound traffic"
  vpc_id      = module.vpc.vpc_id

  ingress {
    description     = "TLS from VPC"
    from_port       = 443
    to_port         = 443
    protocol        = "tcp"
    security_groups = [module.vpc.vpc_default_security_group_id]
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
  type        = "String"
  description = "SG for lambda"
  value       = aws_security_group.ws_lambda_sg.id
}



resource "aws_iam_role" "socket_api_role" {
  name               = "SocketAuctionApiRole"
  assume_role_policy = <<EOF
{ 
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "lambda.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF
}


resource "aws_iam_policy" "lambda_invoke_policy" {
  name = "lambda_invoke_policy"
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        "Action" : [
          "execute-api:Invoke",
          "execute-api:ManageConnections"
        ],
        "Resource" : "arn:aws:execute-api:*:*:*"
      }
    ]
  })
}

resource "aws_iam_policy" "vpc_access_policy" {
  name = "vpc_access_policy"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        "Action" : [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents",
          "ec2:CreateNetworkInterface",
          "ec2:DescribeNetworkInterfaces",
          "ec2:DeleteNetworkInterface",
          "ec2:AssignPrivateIpAddresses",
          "ec2:UnassignPrivateIpAddresses"
        ],
        "Resource" : "*"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "attachment1" {
  role       = aws_iam_role.socket_api_role.name
  policy_arn = aws_iam_policy.vpc_access_policy.arn
}

resource "aws_iam_role_policy_attachment" "attachment2" {
  role       = aws_iam_role.socket_api_role.name
  policy_arn = aws_iam_policy.lambda_invoke_policy.arn
}

resource "aws_ssm_parameter" "socket_role_arn" {
  type        = "String"
  name        = "/lambda/role/socket"
  description = "subnets that lambdas must attach to"
  value       = aws_iam_role.socket_api_role.arn
}

resource "aws_ssm_parameter" "private_subnet1" {
  depends_on  = [module.subnets]
  type        = "String"
  name        = "/lambda/subnet/VPC_SUBNET1"
  description = "subnets that lambdas must attach to"
  value       = module.subnets.private_subnet_ids[0]
}

resource "aws_ssm_parameter" "private_subnet2" {
  depends_on  = [module.subnets]
  type        = "String"
  name        = "/lambda/subnet/VPC_SUBNET2"
  description = "subnets that lambdas must attach to"
  value       = module.subnets.private_subnet_ids[1]
}

resource "aws_ssm_parameter" "private_subnet3" {
  depends_on  = [module.subnets]
  type        = "String"
  name        = "/lambda/subnet/VPC_SUBNET3"
  description = "subnets that lambdas must attach to"
  value       = module.subnets.private_subnet_ids[2]
}

resource "aws_ssm_parameter" "private_subnet4" {
  depends_on  = [module.subnets]
  type        = "String"
  name        = "/lambda/subnet/VPC_SUBNET4"
  description = "subnets that lambdas must attach to"
  value       = module.subnets.private_subnet_ids[3]
}

################# Lambda stuff above ###########


module "subnets" {
  source  = "cloudposse/dynamic-subnets/aws"
  version = "2.4.1"

  availability_zones   = []
  vpc_id               = module.vpc.vpc_id
  igw_id               = [module.vpc.igw_id]
  nat_gateway_enabled  = true
  nat_instance_enabled = false

  context = module.this.context
}

module "redis" {
  source               = "../terraform-aws-elasticache-redis"
  description          = "testing-elasticache"
  replication_group_id = "testing-elasticache-rg"

  availability_zones         = []
  vpc_id                     = module.vpc.vpc_id
  allowed_security_group_ids = [module.vpc.vpc_default_security_group_id, aws_security_group.ws_lambda_sg.id]
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
  type        = "String"
  description = "Redis cluster for lambda"
  value       = module.redis.endpoint
}