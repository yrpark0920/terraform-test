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

############################# Add_On Role #############################
## EKS OIDC 공급자 생성
data "tls_certificate" "eks" {
  url = aws_eks_cluster.this.identity[0].oidc[0].issuer
}

resource "aws_iam_openid_connect_provider" "eks" {
  url = aws_eks_cluster.this.identity[0].oidc[0].issuer 
  client_id_list = ["sts.amazonaws.com"]
  thumbprint_list = [data.tls_certificate.eks.certificates[0].sha1_fingerprint]

  tags = {
    Name = "${var.eks_cluster_name}-eks-irsa"
    EKS_Cluster = var.eks_cluster_name
  }
}

## Role이 필요한 AddOn만 추리기
/*
> local.assume_role_policy_list
{
  "aws-ebs-csi-driver" = {
    "attach_policy" = tolist([
      "AmazonEBSCSIDriverPolicy",
    ])
    "serviceaccount" = "system:serviceaccount:kube-system:ebs-csi-controller-sa"
    "version" = "v1.66.0-eksbuild.1"
  }
}
*/
locals {
  assume_role_policy_list = {
    for k, v in var.cluster_addons : k => v
    if ( v.serviceaccount != null && v.attach_policy != null)
  }
}

## IAM 정책 문서를 쉽게 작성할 수 있도록 도와주는 템플릿(data.aws_iam_policy_document)
data "aws_iam_policy_document" "addon_assume_role_policy" {
  for_each = local.assume_role_policy_list

  statement {
    actions = ["sts:AssumeRoleWithWebIdentity"]
    effect  = "Allow"

    condition {
      test     = "StringEquals"
      variable = "${replace(aws_iam_openid_connect_provider.eks.url, "https://", "")}:sub"
      values   = [each.value.serviceaccount]
    }

    principals {
      identifiers = [aws_iam_openid_connect_provider.eks.arn]
      type        = "Federated"
    }
  }
}

# -------------------------------------------------------------------
# IAM Role 생성 
resource "aws_iam_role" "eks_addon" {
  for_each = local.assume_role_policy_list

  assume_role_policy = data.aws_iam_policy_document.addon_assume_role_policy[each.key].json 
  name = "${each.key}-addon-role"
}

# -------------------------------------------------------------------
## IAM Role에 Policy를 연결해야하는데 1:1 매핑이 가능하므로 flatten을 거친 후 새로운 Map 생성
/*
> eks_addon_policy_map
{
  "aws-ebs-csi-driver/AmazonEBSCSIDriverPolicy" = {
    "addon_name" = "aws-ebs-csi-driver"
    "policy" = "AmazonEBSCSIDriverPolicy"
  }
}
*/
locals {
  eks_addon_flatten_list = flatten([
    for addon_name, addon_info in local.assume_role_policy_list : [
      for policy in addon_info.attach_policy : {
        addon_name = addon_name 
        policy = policy
      }
    ]
  ])

  eks_addon_policy_map = {
    for item in local.eks_addon_flatten_list : "${item.addon_name}/${item.policy}" => item 
  }
}

resource "aws_iam_role_policy_attachment" "eks_addon" {
  for_each = local.eks_addon_policy_map

  role = aws_iam_role.eks_addon[each.value.addon_name].name
  policy_arn = "arn:aws:iam::aws:policy/${each.value.policy}"
}