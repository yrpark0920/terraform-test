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


############################ Associate Subnet <-> RouteTable ############################
resource "aws_route_table_association" "this" {
    for_each = local.rt_information 

    subnet_id = aws_subnet.this[each.value.target_subnet].id
    route_table_id = aws_route_table.this[each.key].id

}

############################ Add Routing into Route Table ############################
## IGW 경로
locals {
    igw_rt_information = {
        for k,v in local.rt_information : k => v if(strcontains(k, "pub"))
    }
}

resource "aws_route" "igw" {
    for_each = local.igw_rt_information

    route_table_id = aws_route_table.this[each.key].id
    destination_cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.this[0].id 
}

## NGW 라우팅
locals {
    ngw_rt_information = {
        for k,v in local.rt_information : k => merge(v,{
            # 1. NGW가 1개만 있으면 무조건 그 NGW 선택 
            # 2. NGW가 여러개 있으면 라우팅 테이블의 AZ와 일치하는 NGW 선택
            # 3. NGW가 없으면 null
            nat_gateway_name = (
                length(local.ngw_information) == 1 ? keys(local.ngw_information)[0] : 
                length(local.ngw_information) > 1 ? try(
                    [for ngw_k, ngw_v in local.ngw_information : ngw_k if ngw_v.az == v.az][0], null
                ) : null 
            )
        }) 
        # main.tf에 명시한 그룹만 선택
        if ( contains(var.allow_nat_route_subnet, v.group) )
    }
}

resource "aws_route" "ngw" {
    for_each = local.ngw_rt_information

    route_table_id = aws_route_table.this[each.key].id
    destination_cidr_block = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.this[each.value.nat_gateway_name].id
}

## 그외 사용자 지정 라우팅