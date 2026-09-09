## pub-bastion에 연결할 ALB 생성 
## 보안 그룹 생성
resource "aws_security_group" "pub-bastion-alb" {
    name = "pub-bastion-alb-sg"
    description = "Security Group for public Bastion ALB"
    vpc_id = aws_vpc.this.id

    tags = merge(
        local.tag_list,
        {
            Name = "${var.vpc_name}-pub-bastion-alb-sg"
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
    pub-bastion-alb-rules = {
        "http" = {
            type = "ingress"
            from_port = 80
            to_port = 80
            protocol = "tcp"
            cidr_blocks = ["0.0.0.0/0"]
        }
        "outbound" = {
            type = "egress"
            from_port = 0
            to_port = 0
            protocol = -1
            cidr_blocks = ["0.0.0.0/0"]
        }
    }
}

resource "aws_security_group_rule" "pub-bastion-alb" {
    for_each = local.pub-bastion-alb-rules

    security_group_id = aws_security_group.pub-bastion-alb.id
    type = each.value.type
    from_port = each.value.from_port
    to_port = each.value.to_port
    protocol = each.value.protocol
    cidr_blocks = each.value.cidr_blocks
}

## Target Group 생성
locals {
    public_bastion_alb_subnets = [ for k,v in local.bastion_create_information : aws_subnet.this[v.subnet].id]
    public_bastion_alb_target_servers = [ for k,v in local.bastion_create_information : aws_instance.pub[k].id]
}

resource "aws_lb_target_group" "pub-bastion-alb" {
    name = "pub-bastion-alb-tg"
    port = 80
    protocol = "HTTP"
    vpc_id = aws_vpc.this.id

    tags = merge(
        local.tag_list,
        {
            Name = "${var.vpc_name}-pub-bastion-alb-tg"
        }
    )
    lifecycle {
        ignore_changes = [
            tags["CreateTime"],
            tags_all["CreateTime"]
        ]
    }
}

resource "aws_lb_target_group_attachment" "pub-bastion-alb" {
    for_each = toset(local.public_bastion_alb_target_servers)

    target_group_arn = aws_lb_target_group.pub-bastion-alb.arn 
    target_id = each.key 
    port = 80
}

# ALB 생성
resource "aws_lb" "pub-bastion-alb" {
    name = "pub-bastion-alb"
    internal = false
    load_balancer_type = "application"
    security_groups = [aws_security_group.pub-bastion-alb.id]
    subnets = local.public_bastion_alb_subnets

    tags = merge(
        local.tag_list,
        {
            Name = "${var.vpc_name}-pub-bastion-alb"
        }
    )
    lifecycle {
        ignore_changes = [
            tags["CreateTime"],
            tags_all["CreateTime"]
        ]
    }
}

# 리스너 생성
resource "aws_lb_listener" "pub-bastion-alb" {
    load_balancer_arn = aws_lb.pub-bastion-alb.arn
    port = 80
    protocol = "HTTP"

    default_action {
        type = "forward"
        target_group_arn = aws_lb_target_group.pub-bastion-alb.arn
    }
}