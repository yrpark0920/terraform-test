########################### Create DB Subnet Group ###########################
locals {
    rds_subnet = var.rds_subnet_az != null ? [ 
        for az in var.rds_subnet_az : "${var.rds_subnet}_${az}"
    ] : []
    rds_subnet_ids = local.rds_subnet != null ? [
        for subnet in local.rds_subnet : var.subnet_ids[subnet]
    ] : []
}

resource "aws_db_subnet_group" "this" {
    count = var.subnet_ids != null ? 1 : 0
    name = "${replace(var.rds_replica_name, "_", "-")}-subnet-group"
    subnet_ids = local.rds_subnet_ids

    tags = {
        Target = replace(var.rds_replica_name, "_", "-")
    }
}

############################# Create DB Replica #############################
resource "aws_db_instance" "replica" {
    replicate_source_db = var.replicate_source_db
    replica_mode = var.replica_mode

    identifier = var.rds_replica_name
    instance_class = var.instance_class
    db_subnet_group_name = var.subnet_ids != null ? aws_db_subnet_group.this[0].name : null 
    storage_type = var.storage_type
    allocated_storage = var.allocated_storage

    multi_az = false
    auto_minor_version_upgrade = false
    skip_final_snapshot = true 
    
}