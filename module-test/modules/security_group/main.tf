############################ Create for Security Group ############################
resource "aws_security_group" "this" {
  name        = var.security_group_name
  description = var.security_group_description
  vpc_id      = var.vpc_id

  tags = {
    Name = replace(var.security_group_name, "_", "-")
  }
}

############################ Add Rules in Security Group ############################
locals {
    ingress_rules = {
        for k,v in var.sg_ingress_rules : k => merge(v, {type = "ingress"})
    }
    egress_rules = {
        for k,v in var.sg_egress_rules : k => merge(v, {type = "egress"})
    }

    security_group_rule_information = merge(local.ingress_rules, local.egress_rules)
}

resource "aws_security_group_rule" "this" {
    for_each = local.security_group_rule_information

    security_group_id = aws_security_group.this.id 

    type = each.value.type 
    from_port = each.value.from_port
    to_port = each.value.to_port 
    protocol = each.value.protocol
    cidr_blocks = lookup(each.value, "cidr_blocks", null)
    source_security_group_id = lookup(each.value, "source_security_group_id", null)
}