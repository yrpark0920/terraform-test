############################# Create EKS Cluster #############################
variable "subnet_ids" {
    description = "EKS 클러스터를 생성할 서브넷 정보를 가지고 있는 output 지정"
    type = map(string)
}

variable "eks_cluster_name" {
    description = "생성하고자하는 EKS 클러스터 이름"
    type = string 
}

variable "eks_cluster_add_policy" {
    description = "EKS Cluster Role에 추가로 매핑할 Policy 목록"
    type = list(string)
    default = []
}

variable "eks_cluster_version" {
    description = "생성할 EKS Cluster 버전"
    type = string
}

variable "eks_cluster_endpoint" {
    description = "EKS 클러스터 엔드포인트 액세스 지정"
    type = string

    validation {
        condition = contains(["private", "public"], var.eks_cluster_endpoint)
        error_message = "[private, public] 중 선택해야합니다."
    }
}

variable "authentication_mode" {
    description = "클러스터 액세스 방법"
    type = string
    
    validation {
        condition = contains(["CONFIG_MAP", "API", "API_AND_CONFIG_MAP"], var.authentication_mode)
        error_message = "[CONFIG_MAP, API, API_AND_CONFIG_MAP] 중에서 선택해야합니다."
    }
}

variable "eks_cluster_subnet" {
    description = "EKS 클러스터를 생성할 서브넷 이름"
    type = string
}

variable "eks_cluster_subnet_az" {
    description = "EKS 클러스터를 생성할 서브넷 가용 영역 지정"
    type = list(string)

    validation {
        condition = length(var.eks_cluster_subnet_az) > 1
        error_message = "2개 이상의 서로 다른 AZ를 지정해야합니다."
    }
}

############################# Create NodeGroup #############################
variable "eks_nodegroup_add_policy" {
    description = "EKS NoeGroup Role에 추가로 매핑할 Policy 목록"
    type = list(string)
    default = []
}

variable "node_group_information" {
    description = "생성할 노드 그룹 정보"
    type = map(object({
        instance_types = optional(list(string), ["t3.medium"])
        capacity_type = optional(string, "ON_DEMAND")
        disk_size = optional(number, 20)
        desired_size = number 
        min_size = number 
        max_size = number
    }))
}

############################# Add AddOn #############################
variable "cluster_addons" {
    desciption = "EKS 클러스터에 추가할 기능"
    type = map(object({
        version = string
        serviceaccount = optional(string)
        attach_policy = optional(list(string))
    }))
}

############################ Add EKS Access ############################
variable "eks_console_access" {
    description = "EKS 클러스터에 액세스 할 수 있도록 EKSAdminViewPolicy 권한 부여할 계정 정보 또는 IAM Role 입력"
    type = list(string)
}

variable "eks_cluster_access" {
    description = "EKS 클러스터에 액세스 할 수 있도록 EKSClusterAdminPolicy 권한 부여할 계정 정보 또는 IAM Role 입력"
    type = list(string)
}