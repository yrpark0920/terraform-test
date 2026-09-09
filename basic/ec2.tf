## DEV 환경에서 사용할 키페어 생성
resource "tls_private_key" "dev" {
    algorithm = "RSA"
}

resource "aws_key_pair" "dev" {
    key_name = "${var.vpc_name}-dev-key"
    public_key = tls_private_key.dev.public_key_openssh

    tags = merge(
        local.tag_list, 
        {
            Name = "${var.vpc_name}-dev-key"
        }
    )
    lifecycle {
        ignore_changes = [
            tags["CreateTime"],
            tags_all["CreateTime"]
        ]
    }
}

resource "local_file" "dev_key" {
    content = tls_private_key.dev.private_key_pem
    filename = "${path.module}/${var.vpc_name}-dev.pem"
    file_permission = "0600"
}

#### Public EC2 ####
## Bastion 생성 관련 환경변수 설정
locals {
    bastion_information = var.enable_bastion.create ? (var.enable_bastion.per_az ? local.public_subnet_map : {keys(local.public_subnet_map)[0] = values(local.public_subnet_map)[0]}) : {}

    bastion_create_information = {
        for k,v in local.bastion_information : "pub-bastion-${v.az}" => {
            name = "pub-web"
            az = v.az
            subnet = k
        }
    }
}

## 퍼블릭 EC2에서 사용할 EIP 생성
resource "aws_eip" "pub" {
    for_each = local.bastion_create_information
    
    tags = merge(
        local.tag_list,
        {
            Name = "${var.vpc_name}-${each.key}-eip"
        }
    )
    lifecycle {
        ignore_changes = [
            tags["CreateTime"],
            tags_all["CreateTime"]
        ]
    }
}


## 보안 그룹 생성
resource "aws_security_group" "pub-bastion" {
    name = "pub-bastion-sg"
    description = "Security Group for public Bastion EC2"
    vpc_id = aws_vpc.this.id

    tags = merge(
        local.tag_list,
        {
            Name = "${var.vpc_name}-pub-bastion-eip"
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
    pub-bastion-rules = {
        "tunneling" = {
            type = "ingress"
            from_port = 3306
            to_port = 3306
            protocol = "tcp"
            cidr_blocks = ["183.98.233.53/32"]
        }
        "ssh" = {
            type = "ingress"
            from_port = 22
            to_port = 22
            protocol = "tcp"
            cidr_blocks = ["12.34.56.78/32", "183.98.233.53/32"]
        }
        "http" = {
            type = "ingress"
            from_port = 80
            to_port = 80
            protocol = "tcp"
            cidr_blocks = ["223.130.200.236/32", "200.130.200.219/32"]
        }
        "pub-alb" = {
            type = "ingress"
            from_port = 80
            to_port = 80
            protocol = "tcp"
            source_security_group_id = aws_security_group.pub-bastion-alb.id
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

resource "aws_security_group_rule" "pub-bastion" {
    for_each = local.pub-bastion-rules 

    security_group_id = aws_security_group.pub-bastion.id
    type = each.value.type
    from_port = each.value.from_port
    to_port = each.value.to_port
    protocol = each.value.protocol
    cidr_blocks = lookup(each.value, "cidr_blocks", null)
    source_security_group_id = lookup(each.value, "source_security_group_id", null)
}

## EC2 생성
data "aws_ami" "ubuntu_2404" {
    most_recent = true
    owners = ["099720109477"]

    filter {
        name = "name"
        values = ["ubuntu/images/hvm-ssd-gp3/ubuntu-noble-24.04-amd64-server-*"]
    }
}

resource "aws_instance" "pub" {
    for_each = local.bastion_create_information

    ami = data.aws_ami.ubuntu_2404.id
    instance_type = "t3.micro"
    subnet_id = aws_subnet.this[each.value.subnet].id
    key_name = aws_key_pair.dev.key_name
    vpc_security_group_ids = [aws_security_group.pub-bastion.id]
    iam_instance_profile = var.eks_information.create == true ? aws_iam_instance_profile.bastion_role_profile.name : null

    tags = merge(
        local.tag_list,
        {
            Name = "${var.vpc_name}-${each.key}"
        }
    )
    lifecycle {
        ignore_changes = [
            tags["CreateTime"],
            tags_all["CreateTime"],
            ami
        ]
    }
}

## Bastion과 EIP 연결
resource "aws_eip_association" "pub-bastion" {
    for_each = local.bastion_create_information

    instance_id = aws_instance.pub[each.key].id
    allocation_id = aws_eip.pub[each.key].id
}