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
        from_port = optional(number)
        to_port = optional(number)
        protocol = string 
        cidrs = optional(list(string))
        security_groups = optional(list(string))
    })
    )
    default = null
}

variable "sg_egress_rules" {
    description = "보안그룹에 추가할 아웃바운드 목록"
    type = map(object({
        from_port = optional(number)
        to_port = optional(number)
        protocol = string 
        cidrs = optional(list(string))
        security_groups = optional(list(string))
    })
    )
    default = null 
}