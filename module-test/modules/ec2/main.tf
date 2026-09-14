################################## Create EC2 Instance ##################################
locals {
    instance_variable = [{
        is_public = var.is_public
        subnet_ids = var.subnet_ids

        instance_name = var.instance_name
        instance_subnet = var.instance_subnet
        instance_subnet_az = var.instance_subnet_az

        instance_ami = var.instance_ami
        instance_type = var.instance_type
        volume_type = var.volume_type
        volume_size = var.volume_size

        instance_security_groups = var.instance_security_groups

        iam_instance_profile = var.iam_instance_profile
    }]

    instance_flat = flatten([
        for item in local.instance_variable : [
            for az in item.instance_subnet_az : {
                name = "${item.instance_name}_${az}"
                subnet = "${item.instance_subnet}_${az}"
                subnet_ids = item.subnet_ids
                is_public = item.is_public 
                ami = item.instance_ami
                type = item.instance_type 
                volume_type = item.volume_type
                volume_size = item.volume_size
                security_groups = item.instance_security_groups
                profile = item.iam_instance_profile
            }
        ]
    ])

    instance_information = {
        for item in local.instance_flat : item.name => merge(item,{
            subnet_id = lookup(item.subnet_ids, item.subnet, null)
        }
        ) 
    }
}

/*
> local.instance_information = {
  "yrpark_dev_bastion_a" = {
    "ami" = "amazon_linux_2023"
    "is_public" = true
    "name" = "yrpark_dev_bastion_a"
    "profile" = tostring(null)
    "security_groups" = tolist([
      "sg-0fe7d6e166f4dbd7d",
    ])
    "subnet" = "yrpark_pub_subnet_a"
    "subnet_id" = "subnet-004d2eb87d0b683ab"
    "subnet_ids" = tomap({
      "yrpark_db_subnet_a" = "subnet-0cbb7a71ba21b2100"
      "yrpark_eks_subnet_a" = "subnet-062b1d3eb854f55ef"
      "yrpark_eks_subnet_b" = "subnet-04b2f8ee02f6dd365"
      "yrpark_pri_subnet_a" = "subnet-0da01c1ac8658dc1f"
      "yrpark_pri_subnet_b" = "subnet-0706408c2d57d6f29"
      "yrpark_pub_subnet_a" = "subnet-004d2eb87d0b683ab"
      "yrpark_pub_subnet_b" = "subnet-09c666957d1e5dd70"
    })
    "type" = "t3.micro"
    "volume_size" = 10
    "volume_type" = "gp3"
  }
}
*/

resource "aws_instance" "this" {
    for_each = local.instance_information
    
    ami = (each.value.ami == "amazon_linux_2023") ? data.aws_ami.amazon_linux_2023.id : data.aws_ami.ubuntu_2404.id
    instance_type = each.value.type 
    key_name = data.aws_key_pair.created.key_name
    
    subnet_id = each.value.subnet_id 
    vpc_security_group_ids = each.value.security_groups

    iam_instance_profile = each.value.profile

    root_block_device {
    volume_type = each.value.volume_type
    volume_size = each.value.volume_size 
    delete_on_termination = true # 인스턴스 삭제 시 볼륨 함께 삭제
    encrypted  = false
  }


    tags = {
        Name = replace(each.key, "_", "-")
    }
}