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
  ingress_cidr_block = merge([
    for k, rule in coalesce(var.sg_ingress_rules, {}) : {
      for idx, cidr in try(rule.cidrs, []) : "${k}_${idx}" => {
        from_port = rule.from_port 
        to_port = rule.to_port 
        ip_protocol = rule.protocol 
        cidr_ipv4 = cidr 
      }
    }
    if try(rule.cidrs, null) != null
  ]...) //local.ingress_cidr_block

  ingress_security_group = merge([
    for k, rule in coalesce(var.sg_ingress_rules, {}) : {
      for idx, security_group_id in try(rule.security_groups, []) : "${k}_${idx}" => {
        from_port = rule.from_port 
        to_port = rule.to_port 
        ip_protocol = rule.protocol 
        referenced_security_group_id = security_group_id
      }
    }
    if try(rule.security_groups, null) != null
  ]...) //local.ingress_security_group

  egress_cidr_block = merge([
    for k, rule in coalesce(var.sg_egress_rules, {}) : {
      for idx, cidr in try(rule.cidrs, []) : "${k}_${idx}" => {
        from_port = rule.from_port 
        to_port = rule.to_port 
        ip_protocol = rule.protocol 
        cidr_ipv4 = cidr 
      }
    }
    if try(rule.cidrs, null) != null
  ]...) //local.egress_cidr_block

  egress_security_group = merge([
    for k, rule in coalesce(var.sg_egress_rules, {}) : {
      for idx, security_group_id in try(rule.security_groups, []) : "${k}_${idx}" => {
        from_port = rule.from_port 
        to_port = rule.to_port 
        ip_protocol = rule.protocol 
        referenced_security_group_id = security_group_id
      }
    }
    if try(rule.security_groups, null) != null
  ]...) //local.egress_security_group
}
## ---------------------Inbound----------------------------
resource "aws_vpc_security_group_ingress_rule" "from_cidr" {
    for_each = local.ingress_cidr_block

    security_group_id = aws_security_group.this.id
    from_port = each.value.from_port
    to_port = each.value.to_port
    ip_protocol = each.value.ip_protocol
    cidr_ipv4 = lookup(each.value, "cidr_ipv4", null)
}

resource "aws_vpc_security_group_ingress_rule" "from_sg" {
    for_each = local.ingress_security_group

    security_group_id = aws_security_group.this.id
    from_port = each.value.from_port
    to_port = each.value.to_port
    ip_protocol = each.value.ip_protocol
    referenced_security_group_id = lookup(each.value, "referenced_security_group_id", null)
}

## ---------------------Outbound----------------------------
resource "aws_vpc_security_group_egress_rule" "from_cidr" {
    for_each = local.egress_cidr_block

    security_group_id = aws_security_group.this.id
    from_port = each.value.from_port
    to_port = each.value.to_port
    ip_protocol = each.value.ip_protocol
    cidr_ipv4 = lookup(each.value, "cidr_ipv4", null)
}

resource "aws_vpc_security_group_egress_rule" "from_sg" {
    for_each = local.egress_security_group

    security_group_id = aws_security_group.this.id
    from_port = each.value.from_port
    to_port = each.value.to_port
    ip_protocol = each.value.ip_protocol
    referenced_security_group_id = lookup(each.value, "referenced_security_group_id", null)
}