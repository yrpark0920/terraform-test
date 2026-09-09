## RDS 생성
## 보안 그룹 생성
resource "aws_security_group" "dev-rds" {
    count = var.rds_mysql.create ? 1 : 0 
    name = "dev-rds-sg"
    description = "Security Group for dev rds"
    vpc_id = aws_vpc.this.id

    tags = merge(
        local.tag_list,
        {
            Name = "${var.vpc_name}-dev-rds-sg"
        }
    )
    lifecycle {
        ignore_changes = [
            tags["CreateTime"],
            tags_all["CreateTime"]
        ]
    }
}

## 보안 그룹 Rule 생성
locals {
    dev-rds-rules = {
        "mysql" = {
            type = "ingress"
            from_port = 3306
            to_port = 3306
            protocol = "tcp"
            source_security_group_id = aws_security_group.pub-bastion.id
        }
    }
}

resource "aws_security_group_rule" "dev-rds" {
    for_each = var.rds_information.create ? local.dev-rds-rules : {}

    security_group_id = aws_security_group.dev-rds.id
    type = each.value.type
    from_port = each.value.from_port
    to_port = each.value.to_port
    protocol = each.value.protocol
    cidr_blocks = lookup(each.value, "cidr_blocks", null)
    source_security_group_id = lookup(each.value, "source_security_group_id", null)
}


## DB 서브넷 그룹 생성
locals {
    db_subnet_list = [
        for k,v in local.subnet_with_az_map : aws_subnet.this[k].id
        if (startswith(k, "pri-db"))
      ]
}

resource "aws_db_subnet_group" "dev-rds" {
    count = var.rds_information.create ? 1 : 0
    name = "dev-rds-subnet-group"
    description = "dev-rds-subnet-group"
    subnet_ids = local.db_subnet_list

    tags = merge(
        local.tag_list,
        {
            Name = "${var.vpc_name}-dev-rds-subnet-group"
        }
    )
    lifecycle {
        ignore_changes = [
            tags["CreateTime"],
            tags_all["CreateTime"]
        ]
    }
}

## 파라미터 그룹 생성
resource "aws_db_parameter_group" "dev-rds-pg" {
    count = var.rds_information.create ? 1 : 0
    name   = "dev-rds-pg"
    family = "mysql8.0"

    parameter {
        name  = "character_set_server"
        value = "utf8"
    }

    parameter {
        name  = "character_set_client"
        value = "utf8"
    }

    tags = merge(
        local.tag_list,
        {
            Name = "${var.vpc_name}-dev-rds-pg"
        }
    )

    lifecycle {
        create_before_destroy = true
        ignore_changes = [
            tags["CreateTime"],
            tags_all["CreateTime"]
        ]
    }
}

## RDS 생성
resource "aws_db_instance" "dev-rds" {
    identifier           = "dev-mysql-rds"
    allocated_storage    = 20
    storage_type         = "gp3"
    db_name              = "yrpark_db"
    engine               = "mysql"
    engine_version       = "8.0"
    instance_class       = "db.t3.micro"
    username             = "yrpark"
    password             = "!Yrpark0920"
    db_subnet_group_name = aws_db_subnet_group.dev-rds.name
    parameter_group_name = aws_db_parameter_group.dev-rds-pg.name
    skip_final_snapshot  = true
    vpc_security_group_ids = [aws_security_group.dev-rds.id] # 보안그룹 지정
    monitoring_interval = 0   # Enhanced Monitoring 비활성화
    performance_insights_enabled = false  # Performance Insights 비활성화
    backup_retention_period = 1

    tags = merge(
        local.tag_list,
        {
            Name = "${var.vpc_name}-dev-rds"
        }
    )
    lifecycle {
        create_before_destroy = true
        ignore_changes = [
            tags["CreateTime"],
            tags_all["CreateTime"]
        ]
    }
}

## RDS Replica 생성
resource "aws_db_instance" "dev-rds-replica" {
    identifier           = "${aws_db_instance.dev-rds.identifier}-replica"
    replicate_source_db  = aws_db_instance.dev-rds.identifier

    instance_class       = aws_db_instance.dev-rds.instance_class
    parameter_group_name = aws_db_instance.dev-rds.parameter_group_name
    vpc_security_group_ids = aws_db_instance.dev-rds.vpc_security_group_ids # 보안그룹 지정

    skip_final_snapshot  = true
    auto_minor_version_upgrade = false
    multi_az = false

    tags = merge(
        local.tag_list,
        {
            Name = "${var.vpc_name}-dev-rds-replica"
        }
    )
    lifecycle {
        create_before_destroy = true
        ignore_changes = [
            tags["CreateTime"],
            tags_all["CreateTime"]
        ]
    }
}