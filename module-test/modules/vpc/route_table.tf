############################ Create Route Table ############################
## 변수 생성
/*
  "yrpark_pri_rt_a" = {
    "az" = "a"
    "group" = "pri"
    "project_code" = "yrpark"
    "target_subnet" = "yrpark_pri_subnet_a"
    "target_subnet_id" = "subnet-0da01c1ac8658dc1f"
  }
  "yrpark_pub_rt_a" = {
    "az" = "a"
    "group" = "pub"
    "project_code" = "yrpark"
    "target_subnet" = "yrpark_pub_subnet_a"
    "target_subnet_id" = "subnet-004d2eb87d0b683ab"
  }
*/
locals {
    rt_temp = [
        for k,v in local.subnet_information : {
            project_code = split("_", k)[0]
            group = strcontains(v.name, "pub") ? "pub" : strcontains(v.name, "pri") ? "pri" : strcontains(v.name, "eks") ? "eks" : strcontains(v.name, "db") ? "db" : "other"
            az = v.az 
            target_subnet = k
            target_subnet_id = aws_subnet.this[k].id
        }
    ]

    rt_information = {
        for item in local.rt_temp : "${item.project_code}_${item.group}_rt_${item.az}" => item
    }
}

resource "aws_route_table" "this" {
    for_each = local.rt_information 
    vpc_id = aws_vpc.this.id

    tags = {
        Name = replace(each.key, "_", "-")
    }
}