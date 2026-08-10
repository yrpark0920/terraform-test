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

# VPC 생성
locals {
  kst_now = timeadd(timestamp(), "9h")

  tag_list = {
    Environment = var.env
    CreateBy = "terraform"
    CreateTime = formatdate("YYYY-MM-DD hh:mm:ss", local.kst_now)
  }
}

resource "aws_vpc" "this" {
  cidr_block = var.vpc_cidr
  enable_dns_support = true
  enable_dns_hostnames = true

  tags = merge(
    local.tag_list,
    {
      Name = var.vpc_name
    }
  )

  lifecycle {
    ignore_changes = [ 
      tags["CreateTime"],
      tags_all["CreateTime"]
      
      ]
  }
}

## 서브넷 생성
locals{
  region_code = "ap-northeast-3"

  subnet_with_az_lists = flatten([
    for name, list in var.subnet_lists : [
      for az in list : {
        name = name
        subnet_cidr_block = cidrsubnet(var.vpc_cidr, var.subnet_newbits, az)
        az = var.subnet_azs[index(list, az)]
      }
    ]
  ])
  subnet_with_az_map = {
    for item in local.subnet_with_az_lists : "${item.name}-${item.az}" => item
  }
}

resource "aws_subnet" "this" {
  for_each = local.subnet_with_az_map

  vpc_id = aws_vpc.this.id
  availability_zone = "${local.region_code}${each.value.az}"
  cidr_block = each.value.subnet_cidr_block

  tags = merge(
    local.tag_list,
    {
      Name = "${each.key}-subnet"
    }
  )

  lifecycle {
    ignore_changes = [ 
      tags["CreateTime"],
      tags_all["CreateTime"]
      
      ]
  }
}
