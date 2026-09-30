output "bastion_ec2_role" {
    description = "EKS 액세스에 추가할 수 있도록 Bastion이 가진 Role 반환"
    value = aws_iam_role.bastion.name
}