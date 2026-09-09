## 서브넷 생성 시 사용할 변수 생성
locals {
    subnet_temp = flatten([
        for name, information in var.subnet_information : [
            for idx,  az in information.subnets : {
                name = name
                az = az
                subnet_cidr = try (
                    information.cidr_block[idx],
                    cidrsubnet(var.vpc_cidr, information.newbits, information.subnet_idx[idx])
                )
                is_public = strcontains(name, "pub")
            }
        ]
    ])

    subnet_information = {
        for item in local.subnet_temp : "${item.name}_${item.az}" => item
    }
}

## 서브넷 생성
resource "aws_subnet" "this" {
    for_each = local.subnet_information

    vpc_id = aws_vpc.this.id 
    availability_zone = "ap-northeast-3${each.value.az}"
    cidr_block = each.value.subnet_cidr

    tags = merge(local.tag_list, {
        Name = replace(each.key, "_", "-")
    })

    lifecycle {
    ignore_changes = [ 
      tags["CreateTime"],
      tags_all["CreateTime"]
      ]
  }
}

## 목적별 서브넷 변수 생성 (해당 결과값이 없을 경우 빈 맵으로 생성)
/*
> module.dev_vpc.public_subnet_information
{
  "yrpark_pub_subnet_a" = {
    "az" = "a"
    "is_public" = true
    "name" = "yrpark_pub_subnet"
    "subnet_cidr" = "10.0.0.0/24"
  }
  "yrpark_pub_subnet_b" = {
    "az" = "b"
    "is_public" = true
    "name" = "yrpark_pub_subnet"
    "subnet_cidr" = "10.0.1.0/24"
  }
}
*/
locals {
    public_subnet_information = { 
        for k,v in local.subnet_information : k => v 
        if (split("_", k)[1] == "pub") 
    }
    private_subnet_information = {
        for k,v in local.subnet_information : k => v 
        if (split("_", k)[1] == "pri") 
    }
    eks_subnet_information = {
        for k,v in local.subnet_information : k => v 
        if (split("_", k)[1] == "eks") 
    }
    db_subnet_information = {
        for k,v in local.subnet_information : k => v 
        if (split("_", k)[1] == "db") 
    }
}