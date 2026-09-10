variable "instance_name" {
    description = "생성할 인스턴스 이름" 
    type = string
}

variable "instance_subnet" {
    description = "인스턴스가 위치할 서브넷"
    type = string
}

variable "instance_subnet_az" {
    description = "인스턴스가 위치할 서브넷의 가용영역"
    type = list(string)
}

variable "instance_security_group" {
    description = "인스턴스의 보안 그룹 지정"
    type = string 
}

variable "instance_ami" {
    description = "인스턴스의 이미지 지정"
    type = string

    validation {
        condition = contains(["amazon_linux_2023", "ubuntu"], var.instance_ami)
        error_message = "현재 ["amazon_linux_2023", "ubuntu"] 중에서 선택 가능합니다."
    }
}

variable "instance_type" {
    description = "인스턴스 타입 지정" 
    type = string 
}

variable "volume_type" {
    description = "인스턴스 볼륨 타입 지정"
    type = optional(string)
    default = "gp3"
}

variable "volume_size" {
    description = "인스턴스 볼륨 크기 지정" 
    type = number 

    validation {
        condition = (var.volume_size >= 8) ? true : false
        error_message = "EBS의 볼륨 크기는 최소 8 이상이어야합니다."
    }
    
}

variable "sg_ingress_rules" {
    description = "보안그룹에 추가할 인바운드 목록"
    type = map(object{
        from_port = number
        to_port = number
        protocol = string 
        cidr_blocks = optional(list(string))
        source_security_group_ids = optional(list(string))
    })
}

variable "sg_egress_rules" {
    description = "보안그룹에 추가할 아웃바운드 목록"
    type = map(object{
        from_port = number
        to_port = number
        protocol = string 
        cidr_blocks = optional(list(string))
        source_security_group_ids = optional(list(string))
    })
}