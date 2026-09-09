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
        subnet = string
        per_az = bool
    })
}

variable "enable_bastion" {
    description = "Bastion 인스턴스 생성 여부"
    type = object ({
        create = bool
        per_az = bool 
    })
}

variable "rds_information" {
    description = "RDS 인스턴스 정보 입력"
    sensitive   = true
    type = object ({
        create = bool
        replica = bool 
        indentifier = string
        engine = string
        engine_version = string
        allocated_storage = number 
        db_name = string
        username = string
        password = string
        instance_class = string
    })
}

variable "eks_information" {
    description = "EKS Cluster 정보"
    type = object ({
        create = bool
        name = string
        authentication_mode = string 
        k8s_version = string 
        private_access = bool 
        public_access = bool 
        tags = map(string)
        addon_list = map(string)
    })
}

variable "eks_node_groups" {
    description = "생성할 EKS Node Group 정보"
    type = map(object({
        instance_type = list(string)
        disk_size = optional(number, 20)
        min_size = number 
        max_size = number 
        desired_size = number 
        capacity_type = optional(string, "ON_DEMAND")
        labels = map(string)
    }))
}

variable "eks_cluster_role_information" {
    description = "EKS Cluster Role 정보"
    type = object ({
        name = string
        policy = string
        tags = map(string)
    })
}

variable "eks_node_group_role_information" {
    description = "EKS Node Group Role 정보"
    type = object ({
        name = string 
        policy = list(string)
        tags = map(string)
    })
}

variable "eks_entry_access" {
    description = "EKS Access 추가할 목록" 
    type = map(object({
       principal = string 
       type = string 
       policy_arn = string 
       access_scope_type = string  
    }))
}