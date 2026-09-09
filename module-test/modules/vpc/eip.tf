############################### NAT Gateway ###############################
## NAT에서 사용할 EIP 생성
resource "aws_eip" "nat" {
    for_each = local.ngw_information

    tags = {
        Name = "${replace(each.key, "_", "-")}-eip"
        CreatedBy = "Terraform"
    }
}
