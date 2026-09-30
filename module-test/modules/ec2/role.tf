############################ Add Bastion Role ############################
resource "aws_iam_role" "bastion" {
    name = "bastion-ec2-role"

    assume_role_policy = jsonencode({
        Version = "2012-10-17"
        Statement = [
            {
                Action = "sts:AssumeRole"
                Effect = "Allow" 
                Sid = "" 
                Principal = {
                    Service = "ec2.amazonaws.com"
                }
            }
        ]
    })
}

resource "aws_iam_role_policy_attachment" "bastion" {
    for_each = toset(var.iam_instance_profile_policy)

    role = aws_iam_role.bastion.name 
    policy_arn = "arn:aws:iam::aws:policy/${each.key}"
}

resource "aws_iam_instance_profile" "bastion_profile" {
    name = "bastion_profile" 
    role = aws_iam_role.bastion.name 
}
