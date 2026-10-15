variable "subnet_ids" {
    description = "RDS를 생성할 서브넷 정보를 가지고 있는 output 지정"
    type = map(string)
    default = null 
}

variable "rds_subnet" {
    description = "RDS를 생성할 서브넷 이름"
    type = string
    default = null
}

variable "rds_subnet_az" {
    description = "RDS 생성할 서브넷의 가용 영역 지정"
    type = list(string)
    default = null

    validation {
        condition = length(var.rds_subnet_az) > 1
        error_message = "2개 이상의 서로 다른 AZ를 지정해야합니다."
    }
}

variable "replica_mode" {
    description = "복제본 옵션"
    default = null
}

variable "rds_replica_name" {
    description = "RDS Replica 이름"
    type = string
}

variable "replicate_source_db" {
    description = "어떤 마스터를 복제할지 지정"
    type = string 
}

variable "instance_class" {
    description = "RDS Replica 인스턴스 유형"
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