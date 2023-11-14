terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.0"
    }
  }
}

# Main region where the resources should be created in
# Should be close to the location of your viewers
provider "aws" {
  region = "us-west-2"
}

# Provider used for creating the Lambda@Edge function which must be deployed
# to us-east-1 region (Should not be changed)
provider "aws" {
  alias  = "global_region"
  region = "us-east-1"
}

resource "aws_s3_bucket_ownership_controls" "static_upload" {
  bucket = module.tf_next.upload_bucket_id
  rule {
    object_ownership = "BucketOwnerPreferred"
  }
}

resource "aws_s3_bucket_acl" "static_upload" {
  depends_on = [aws_s3_bucket_ownership_controls.static_upload]

  bucket = module.tf_next.upload_bucket_id
  acl    = "private"
}

##########################
# Terraform Next.js Module
##########################

module "tf_next" {
  source  = "milliHQ/next-js/aws"
  version = "1.0.0-canary.4"

  deployment_name = "atomic-deployments"
  providers = {
    aws.global_region = aws.global_region
  }
}

#########
# Outputs
#########

output "api_endpoint" {
  value = module.tf_next.api_endpoint
}

output "api_endpoint_access_policy_arn" {
  value = module.tf_next.api_endpoint_access_policy_arn
}