variable "subnet_ids" {
    description = "RDS를 생성할 서브넷 정보를 가지고 있는 output 지정"
    type = map(string)
}

variable "rds_name" {
    description = "생성할 RDS 이름"
    type = string
}

variable "rds_subnet" {
    description = "RDS를 생성할 서브넷 이름"
    type = string
}

variable "rds_subnet_az" {
    description = "RDS 생성할 서브넷의 가용 영역 지정"
    type = list(string)

    validation {
        condition = length(var.rds_subnet_az) > 1
        error_message = "2개 이상의 서로 다른 AZ를 지정해야합니다."
    }
}

variable "rds_family" {
    description = "생성할 RDS의 파라미터 그룹 유형" 
    type = string
}

variable "rds_parameter_group_content" {
    description = "DB Parameter Group에 변경하여 적용할 내용"
    type = map(string)
}

############################# Create DB Instance #############################
variable "instance_class" {
    description = "DB 인스턴스 유형"
    type = string 
}

variable "engine" {
    description = "DB 엔진 지정"
    type = string
}

variable "engine_version" {
    description = "DB 엔진 버전 지정"
    type = string 
}

variable "storage_type" {
    description = "DB 스토리지 유형"
    type = string 
}

variable "allocated_storage" {
    description = "DB 인스턴스 볼륨 크기 지정"
    type = number 
}

variable "db_name" {
    description = "DB 클러스터 식별자 지정"
    type = string 
}

variable "username" {
    description = "마스터 사용자 이름"
    type = string 
}

variable "password" {
    description = "마스터 사용자 패스워드"
    type = string 
    default = null
}

variable "multi_az" {
    description = "Multi_AZ 활성화 여부"
    type = bool 
}

variable "vpc_security_group_ids" {
    description = "RDS 보안 그룹 지정"
    type = list(string)
}