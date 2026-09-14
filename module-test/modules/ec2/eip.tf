locals {
    ec2_eip_information = {
        for k,v in local.instance_information : k => v 
        if v.is_public 
    }
}

################################## Create EC2 Instance EIP ##################################
resource "aws_eip" "ec2_eip" {
    for_each = local.ec2_eip_information

    tags = {
        Name = "${replace(each.key, "_", "-")}-eip"
    }

}

################################## Attach EC2 Instance EIP ##################################
resource "aws_eip_association" "this" {
    for_each = local.ec2_eip_information
    
    instance_id = aws_instance.this[each.key].id 
    allocation_id = aws_eip.ec2_eip[each.key].id
}