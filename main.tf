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

    ## NAT 라우팅 추가할 그룹 지정
    allow_nat_route_subnet = ["eks"]

} // module.dev_vpc

module "dev_bastion" {
  source = "./modules/ec2"

  instance_name = "yrpark_dev_bastion"
  instance_subnet = "yrpark_pub_subnet"
  instance_subnet_az = ["a"] 

  instance_ami = "amazon_linux_2023"
  instance_type = "t3.micro"
  volume_type = "gp3"
  volume_size = 10

  instance_security_group = "yrpark_dev_bastion_sg"

  ## 인바운드 규칙 설정
  sg_ingress_rules = {
    "http" = {
      from_port = 80
      to_port = 80
      protocol = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
      # source_security_group_ids = []
    }
  }

  ## 아웃바운드 규칙 설정
  sg_egress_rules = {
    "outbound_default" = {
      from_port = 0
      to_port = 0
      protocol = -1
      cidr_blocks = ["0.0.0.0/0"]
    }
  }
}