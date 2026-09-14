################################## Create Security Group ##################################
variable "vpc_id" {
    description = "보안 그룹을 생성할 VPC ID"
    type = string
}

variable "security_group_name" {
    description = "생성할 보안 그룹 이름"
    type = string
}

variable "security_group_description" {
    description = "보안 그룹 설명"
    type = string 
    default = null
}

variable "sg_ingress_rules" {
    description = "보안그룹에 추가할 인바운드 목록"
    type = map(object({
        from_port = number
        to_port = number
        protocol = string 
        cidr_blocks = optional(list(string))
        source_security_group_id = optional(string)
    })
    )
}

variable "sg_egress_rules" {
    description = "보안그룹에 추가할 아웃바운드 목록"
    type = map(object({
        from_port = number
        to_port = number
        protocol = string 
        cidr_blocks = optional(list(string))
        source_security_group_id = optional(string)
    })
    )
}