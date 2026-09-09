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