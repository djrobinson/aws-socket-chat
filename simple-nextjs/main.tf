provider "aws" {
  region = "us-west-2" #customize your region
}

provider "aws" {
  alias  = "global_region"
  region = "us-east-1" #must be us-east-1
}

module "next_serverless" {
  source  = "Nexode-Consulting/nextjs-serverless/aws"

  deployment_name = "nextjs-serverless-3" #needs to be unique since it will create an s3 bucket
  region          = "us-west-2" #customize your region
  base_dir        = "./"
}

output "next_serverless" {
  value = module.next_serverless
}