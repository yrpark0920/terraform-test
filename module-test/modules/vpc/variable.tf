variable "vpc_cidr" {
    description = "생성할 VPC의 CIDR"
    type = string
    default = "10.0.0.0/16"
}

variable "vpc_name" {
    description = "생성할 VPC의 이름"
    type = string
}

variable "env" {
    description = "생성할 리소스의 환경"
    type = string
    default = "dev"

    validation {
        condition = contains(["dev", "stg", "prd"], var.env)
        error_message = "env에는 [dev, stg, prd]만 입력할 수 있습니다."
    }
}

variable "subnet_information" {
    description = "생성할 서브넷 정보"
    type = map(object({
        subnets = list(string)
        cidr_block = optional(list(string))
        newbits = optional(number)
        subnet_idx = optional(list(number))
    }))
}

variable "create_ngw_strategy" {
    description = "생성할 NGW 정보"
    type = string

    validation {
        condition = contains(["none", "single", "per_az"], var.create_ngw_strategy)
        error_message = "[none, single, per_az] 중에서 선택하셔야 합니다."
    }
}

variable "allow_nat_route_subnet" {
    description = "NAT 라우팅 경로를 추가할 서브넷 그룹 지정"
    type = list(string)

    validation {
        condition = alltrue([
            for subnet in var.allow_nat_route_subnet : contains(["eks", "pri", "db"], subnet)
        ])
        error_message = "[eks, pri, db] 중에서 선택하셔야 합니다."
    }
}