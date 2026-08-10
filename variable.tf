variable "env"{
    description = "VPC를 생성할 환경"
    type = string
}

variable "vpc_name" {
    description = "생성할 VPC 이름"
    type = string

    validation {
        condition = var.vpc_name != "" && can(regex("^[a-zA-Z-]+$", var.vpc_name))
        error_message = "VPC 이름에는 대소문자와 하이픈(-)만 입력할 수 있습니다."
    }
}

variable "vpc_cidr" {
    description = "생성할 VPC의 CIDR"
    type = string
}

variable "subnet_newbits" {
    description = "기존 네트워크 길이에 추가할 비트 수"
    type = number
}

variable "subnet_azs" {
    description = "리소스를 생성할 가용 영역 지정"
    type = list(string)
}

variable "subnet_lists" {
    description = "생성할 서브넷의 이름과 가용 영역 지정"
    type = map(list(number))
}

variable "nat" {
    description = "NAT 생성 관련"
    type = object ({
        create = bool
        subnet = "string"
        per_az = bool
    })
}
