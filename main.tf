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

  is_public = true
  key_pair_name = "yrpark-dev-key-pair"
  subnet_ids = module.dev_vpc.subnet_ids

  instance_name = "yrpark_dev_bastion"
  instance_subnet = "yrpark_pub_subnet"
  instance_subnet_az = ["a"] 

  instance_ami = "amazon_linux_2023"
  instance_type = "t3.micro"
  volume_type = "gp3"
  volume_size = 10

  instance_security_groups = [module.dev_bastion_sg.sg_id]

  # iam_instance_profile = ""
} // module.dev_bastion


module "dev_bastion_sg" {
  source = "./modules/security_group"
  vpc_id = module.dev_vpc.vpc_id

  security_group_name = "yrpark_dev_bastion_sg"
  #security_group_description = ""

  ## 인바운드 규칙 설정
  sg_ingress_rules = {
    "http" = {
      from_port = 80
      to_port = 80
      protocol = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
      # source_security_group_id = []
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
} //module.dev_bastion_sg

module "dev_eks" {
  source "./modules/eks"
  subnet_ids = module.dev_vpc.subnet_ids 

  ## Cluster 변수 설정
  eks_cluster_name = "yraprk_dev_eks_cluster"
  # eks_cluster_add_policy = [""]
  eks_cluster_version = "1.36"
  eks_cluster_endpoint = "private"
  authentication_mode = "API_AND_CONFIG_MAP"
  eks_cluster_subnet = "yrpark_eks_subnet"
  eks_cluster_subnet_az = ["a", "b"]

  ## NodeGroup 변수 설정
  # eks_nodegroup_add_policy = [""]
  
  node_group_information = {
    "mgmt" = {
      instance_types = ["t3.large"]
      capacity_type = "ON_DEMAND"
      disk_size = 30
      desired_size = 1
      min_size = 0
      max_size = 2
    },
    "app" = {
      instance_types = ["t3.medium"]
      capacity_type = "ON_DEMAND"
      disk_size = 20 
      desired_size = 1 
      min_size = 0
      max_size = 1
    }
  } // variable "node_groups"

  ## EKS Addon 
  cluster_addons = {
    "vpc-cni" = {
      version = "v1.22.4-eksbuild.3"
    }
    "kube-proxy" = {
      version = "v1.36.0-eksbuild.25"
    }
    "coredns" = {
      version = "v1.14.3-eksbuild.23"
    }
    "aws-ebs-csi-driver" = {
      version = "v1.66.0-eksbuild.1"
      serviceaccount = "system:serviceaccount:kube-system:ebs-csi-controller-sa"
      attach_policy = ["service-role/AmazonEBSCSIDriverPolicy"]
    }
  } //cluster_addons

  ## EKS Access 
  eks_console_access = ["yrpark@ensmart.co.kr"]  # EKSAdminViewPolicy 부여
}