locals {
    rds_subnet = [ 
        for az in var.rds_subnet_az : "${var.rds_subnet}_${az}"
    ]
    rds_subnet_ids = [
        for subnet in local.rds_subnet : var.subnet_ids[subnet]
    ]
}
############################# Create DB Subnet Group #############################
resource "aws_db_subnet_group" "this" {
    name = "${replace(var.rds_name, "_", "-")}-subnet-group"
    subnet_ids = local.rds_subnet_ids

    tags = {
        Target = replace(var.rds_name, "_", "-")
    }
}


############################# Create DB Parameter Group #############################
resource "aws_db_parameter_group" "this" {
    name = "${replace(var.rds_name, "_", "-")}-subnet-group"
    family = var.rds_family

    dynamic "parameter" {
        for_each = var.rds_parameter_group_content 
        content {
            name = parameter.key
            value = parameter.value 
        }
    }
}


############################# Create DB Instance #############################
resource "aws_db_instance" "master" {
    identifier = replace(var.rds_name, "_", "-")
    engine = var.engine
    engine_version = var.engine_version
    instance_class = var.instance_class
    storage_type = var.storage_type
    allocated_storage = var.allocated_storage
    db_subnet_group_name = aws_db_subnet_group.this.name
    parameter_group_name = aws_db_parameter_group.this.name
    vpc_security_group_ids = var.vpc_security_group_ids

    db_name = var.db_name
    username = var.username
    password = var.password
    multi_az = var.multi_az

    skip_final_snapshot = true 
    auto_minor_version_upgrade = false 
    backup_retention_period = var.backup_retention_period

    apply_immediately = true

}