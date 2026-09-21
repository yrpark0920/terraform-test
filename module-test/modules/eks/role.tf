############################# Create EKS Cluster Role #############################
resource "aws_iam_role" "eks_cluster_role" {
  name = "${var.eks_cluster_name}-cluster-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = ["sts:AssumeRole", "sts:TagSession"]
        Effect = "Allow"
        Sid    = ""
        Principal = {
          Service = "eks.amazonaws.com"
        }
      },
    ]
  })

  tags = {
    eks_cluster_role = var.eks_cluster_name
  }
}

## -----------------------------------------------------------------
locals {
    eks_cluster_default_policy = ["AmazonEKSClusterPolicy"]

    eks_cluster_policy = toset(concat(local.eks_cluster_default_policy, var.eks_cluster_add_policy))
}

resource "aws_iam_role_policy_attachment" "eks_cluster_policy" {
    for_each = local.eks_cluster_policy

  role       = aws_iam_role.eks_cluster_role.name
  policy_arn = "arn:aws:iam::aws:policy/${each.value}"
}


############################# Create NodeGroup Role #############################
resource "aws_iam_role" "eks_nodegroup_role" {
  name = "${var.eks_cluster_name}-nodegroup-role"

  assume_role_policy = jsonencode({
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "ec2.amazonaws.com"
      }
    }]
    Version = "2012-10-17"
  })
}

## -----------------------------------------------------------------
locals {
    eks_nodegroup_default_policy = [
        "AmazonEKSWorkerNodePolicy",
        "AmazonEKS_CNI_Policy",
        "AmazonEC2ContainerRegistryReadOnly"
        ]

    eks_nodegroup_policy = toset(concat(local.eks_nodegroup_default_policy, var.eks_nodegroup_add_policy))
}

resource "aws_iam_role_policy_attachment" "eks_nodegroup_policy" {
    for_each = local.eks_nodegroup_policy

  role       = aws_iam_role.eks_nodegroup_role.name
  policy_arn = "arn:aws:iam::aws:policy/${each.value}"
}