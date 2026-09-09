############################ Internet Gateway ############################
## IGW 게이트웨이 생성을 위한 변수 생성
locals {
    create_igw_yn = anytrue([ for k,v in local.subnet_information : v.is_public ])
}

## IGW 생성
resource "aws_internet_gateway" "this" {
    count = local.create_igw_yn == true? 1 : 0

    vpc_id = aws_vpc.this.id 

    tags = {
        Environment = var.env
        CreateBy = "terraform"
        Name = "${var.vpc_name}-igw"
    }
}

############################### NAT Gateway ###############################
## NGW 게이트웨이 생성을 위한 변수 생성
locals{
    # 퍼블릭 서브넷의 첫 번째 Key 추출 (single 상황 대비)
    first_pub_key = length(keys(local.public_subnet_information)) > 0 ? keys(local.public_subnet_information)[0] : null 
    
    # first_pub_key가 null이 아닐 때만 split 수행
    project_code = local.first_pub_key != null ? split("_", local.first_pub_key)[0] : null 

    # first_pub_key가 null이 아닐 때만 split 수행하며, split은 -1 인덱스 지원하지 않음 
    single_az = local.first_pub_key != null ? split("_", local.first_pub_key)[3] : null 

    # 사용자 입력 값에 따라 NGW 생성할 서브넷 정보 추출 
    ngw_information = (
        var.create_ngw_strategy == "single" && local.first_pub_key != null ? {
           "${local.project_code}_ngw_${local.single_az}" = local.public_subnet_information[local.first_pub_key]
        } : 
        var.create_ngw_strategy == "per_az" ? {for k,v in local.public_subnet_information : "${local.project_code}_ngw_${v.az}" => v} : {}
        )
}

## NAT 게이트웨이 생성
resource "aws_nat_gateway" "this" {
    for_each = local.ngw_information 

    allocation_id = aws_eip.nat[each.key].id
    subnet_id = aws_subnet.this["${each.value.name}_${each.value.az}"].id

    tags = {
        Name = "${replace(each.key, "_", "-")}-ngw"
    }
}