## EKS Cluster Role 생성
locals {
    eks_cluster_role_information = { 
        "eks_cluster_role" = merge(
            try(var.eks_cluster_role_information, {}), 
          {
            create = var.eks_information.create ? true : false
          }
        )
    }
}

resource "aws_iam_role" "eks_cluster" {
    for_each = { 
        for k,v in local.eks_cluster_role_information : k => v 
        if v.create == true
    }

    name = each.value.name 

    assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Sid    = ""
        Principal = {
          Service = "eks.amazonaws.com"
        }
      },
    ]
  })

    tags = each.value.tags
}

resource "aws_iam_role_policy_attachment" "eks_cluster_policy" {
  for_each = {
    for k, v in local.eks_cluster_role_information : k => v
    if v.create == true
  }

  role       = aws_iam_role.eks_cluster[each.key].name
  policy_arn = "arn:aws:iam::aws:policy/${each.value.policy}"
}

## Node Group Role 생성
locals {
    node_group_role_information = { 
        "node_group_role" = merge(
            try(var.eks_node_group_role_information, {}), 
          {
            create = var.eks_information.create ? true : false
          }
        )
    }
}

resource "aws_iam_role" "eks_node" {
    for_each = { 
        for k,v in local.node_group_role_information : k => v 
        if v.create == true
    }

    name = each.value.name 

    assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Sid    = ""
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      },
    ]
  })

    tags = each.value.tags
}

locals {
  node_group_policy_object = flatten([
    for k,v in local.node_group_role_information : [
      for policy in v.policy : {
        policy_name = policy
        policy_arn = "arn:aws:iam::aws:policy/${policy}"
      }
    ]
    if v.create == true
  ])

  node_group_policy_map = {
    for item in local.node_group_policy_object : "${item.policy_name}" => item
  }
}

resource "aws_iam_role_policy_attachment" "node_group_policy" {

  for_each = local.node_group_policy_map

  role       = aws_iam_role.eks_node["node_group_role"].name
  policy_arn = each.value.policy_arn
}


## Bastion에서 사용할 Role 생성(EKS 컨트롤 목적)
resource "aws_iam_role" "bastion_eks_role" {
  name = "yrpark-bastion-eks-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Sid    = ""
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      },
    ]
  })

  tags = {
    CreatedBy = "Terraform"
    Purpose = "Using kubectl command in bastion server"
  }
}


resource "aws_iam_role_policy_attachment" "bastion_eks_policy" {
  role       = aws_iam_role.bastion_eks_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
}

# 생성한 Bastion Role을 EC2에 연결하기 위해 Instance Profile 생성
resource "aws_iam_instance_profile" "bastion_role_profile" {
  name = "bastion_role_profile"
  role = aws_iam_role.bastion_eks_role.name
}