## 인터넷 게이트웨이 생성 
## 퍼블릭 서브넷이 있어야 생성되도록 
locals{
    create_igw_yn = anytrue([for k,v in local.subnet_with_az_map : split("-", k)[0]=="pub"])
}

resource "aws_internet_gateway" "this" {
    count = local.create_igw_yn ? 1 : 0
    vpc_id = aws_vpc.this.id 

    tags = merge(
        local.tag_list,
        {
            Name = "${var.vpc_name}-igw"
        }
    )

    lifecycle {
    ignore_changes = [ 
      tags["CreateTime"],
      tags_all["CreateTime"]
      
      ]
  }
}

## 퍼블릭 라우트 테이블 생성
## 인터넷 게이트웨이가 있어야 생성되도록 
resource "aws_route_table" "public" {
    vpc_id = aws_vpc.this.id

    tags = merge(
        local.tag_list,
        {
            Name = "${var.vpc_name}-public-rt"
        }
    )

    lifecycle {
        precondition {
            condition = length(aws_internet_gateway.this) > 0
            error_message = "public 라우트 테이블을 만들기 위해서는 인터넷 게이트웨이가 필요합니다."
        }

        ignore_changes = [
            tags["CreateTime"],
            tags_all["CreateTime"]
        ]
    }
}

## 퍼블릭 라우트 테이블에 IGW 라우트 추가
resource "aws_route" "public_internet" {
    route_table_id = aws_route_table.public.id
    destination_cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.this[0].id
}

## 퍼블릭 라우트 테이블에 서브넷 연결
/*
{
  "pub-nat-a" = {
    "az" = "a"
    "name" = "pub-nat"
    "subnet_cidr_block" = "10.0.0.0/24"
  }
  "pub-nat-c" = {
    "az" = "c"
    "name" = "pub-nat"
    "subnet_cidr_block" = "10.0.1.0/24"
  }
}
*/
locals {
    public_subnet_map = {
        for k,v in local.subnet_with_az_map : k => v
        if (startswith(k, "pub"))
    }
}

resource "aws_route_table_association" "public" {
    for_each = local.public_subnet_map

    subnet_id = aws_subnet.this[each.key].id
    route_table_id = aws_route_table.public.id
}


## NAT Gateway에서 사용할 EIP 생성
locals{
    nat_subnet_information_map = var.nat.create ? (var.nat.per_az ? local.public_subnet_map : { keys(local.public_subnet_map)[0] = values(local.public_subnet_map)[0]}) : {}
}


resource "aws_eip" "nat" {
    for_each = local.nat_subnet_information_map
    
    tags = merge(
        local.tag_list,
        {
            Name = "${var.vpc_name}-${each.key}-eip"
        }
    )
    lifecycle {
        ignore_changes = [
            tags["CreateTime"],
            tags_all["CreateTime"]
        ]
    }
}

## NAT Gateway 생성
resource "aws_nat_gateway" "this" {
    for_each = local.nat_subnet_information_map

    allocation_id = aws_eip.nat[each.key].id
    subnet_id = aws_subnet.this[each.key].id

    tags = merge(
        local.tag_list,
        {
            Name = "${var.vpc_name}-${each.key}-nat"
        }
    )
    lifecycle {
        ignore_changes = [
            tags["CreateTime"],
            tags_all["CreateTime"]
        ]
    }
}


## 프라이빗 라우트 테이블 생성
resource "aws_route_table" "private" {

    for_each = toset(var.subnet_azs)
    vpc_id = aws_vpc.this.id

    tags = merge(
        local.tag_list,
        {
            Name = "${var.vpc_name}-private-${each.key}-rt"
        }
    )

    lifecycle {
        ignore_changes = [
            tags["CreateTime"],
            tags_all["CreateTime"]
        ]
    }
}

## 프라이빗 라우트 테이블에 NAT Gateway 라우팅 규칙 추가 
locals{
    nat_az_list = slice(var.subnet_azs, 0, length(local.nat_subnet_information_map))
    nat_az_mapping = {
        for k in var.subnet_azs : k => (contains(local.nat_az_list, k)? "pub-nat-${k}" : "pub-nat-${local.nat_az_list[0]}")
    }
}

resource "aws_route" "private_internet" {
    for_each = local.nat_az_mapping

    route_table_id = aws_route_table.private[each.key].id
    destination_cidr_block = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.this[each.value].id
}

## 프라이빗 라우트 테이블에 서브넷 연결
locals {
    private_subnet_map = {
        for k,v in local.subnet_with_az_map : k => v
        if (startswith(k, "pri"))
    }
}

resource "aws_route_table_association" "private" {
    for_each = local.private_subnet_map

    subnet_id = aws_subnet.this[each.key].id
    route_table_id = aws_route_table.private[each.value.az].id
}
