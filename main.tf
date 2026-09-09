terraform{
  required_providers { 
    aws = {
      source = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

# AWS Provider 설정
provider "aws" {
  region = "ap-northeast-3"
}

module "dev_vpc" {
    source ="./modules/vpc"

    ## VPC 변수 지정
    vpc_name = "yrpark-dev-vpc"
    vpc_cidr = "10.0.0.0/16"
    env = "dev"

    ## 서브넷 변수 지정
    subnet_information = {
        "yrpark_pub_subnet" = {
        subnets = ["a", "b"]
        cidr_block = ["10.0.0.0/24","10.0.1.0/24"]
        }
        "yrpark_pri_subnet" = {
            subnets = ["a", "b"]
            newbits = 8
            subnet_idx = [2,3]
        }
        "yrpark_eks_subnet" = {
            subnets = ["a", "b"]
            cidr_block = ["10.0.4.0/23", "10.0.6.0/23"]
        }
        "yrpark_db_subnet" = {
            subnets = ["a"]
            newbits = 8
            subnet_idx = [9]
        }
    } //subnet_information

    ## NAT 변수 지정
    create_ngw_strategy = "per_az"

} // module.dev_vpc
