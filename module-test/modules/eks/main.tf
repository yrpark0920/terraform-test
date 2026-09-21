############################# Create EKS Cluster #############################
locals {
    eks_cluster_subnet = [
        for az in var.eks_cluster_subnet_az : "${var.eks_cluster_subnet}_${az}"
    ]

    eks_cluster_subnet_ids = [
        for subnet in local.eks_cluster_subnet : var.subnet_ids[subnet]
    ]
}

resource "aws_eks_cluster" "this" {
  name = replace(var.eks_cluster_name, "_", "-")

  access_config {
    authentication_mode = var.authentication_mode
  }

  role_arn = aws_iam_role.eks_cluster_role.arn
  version  = var.eks_cluster_version

  vpc_config {
    endpoint_private_access = var.eks_cluster_endpoint == "private" ? true : false 
    endpoint_public_access = var.eks_cluster_endpoint == "public" ? true : false
    subnet_ids = local.eks_cluster_subnet_ids
  }

  depends_on = [
    aws_iam_role_policy_attachment.eks_cluster_policy["AmazonEKSClusterPolicy"]
  ]
}


############################# Create NodeGroup #############################
locals{
    node_group_information = var.node_group_information
}

resource "aws_eks_node_group" "this" {
    for_each = local.node_group_information

    cluster_name = aws_eks_cluster.this.name
    node_role_arn = aws_iam_role.eks_nodegroup_role.arn 
    subnet_ids = local.eks_cluster_subnet_ids

    node_group_name = each.key

    scaling_config {
        desired_size = each.value.desired_size
        max_size = each.value.max_size
        min_size = each.value.min_size
    }

    update_config {
        max_unavailable = 1
    }

    depends_on = [
        aws_iam_role_policy_attachment.eks_nodegroup_policy["AmazonEKSWorkerNodePolicy"],
        aws_iam_role_policy_attachment.eks_nodegroup_policy["AmazonEKS_CNI_Policy"],
        aws_iam_role_policy_attachment.eks_nodegroup_policy["AmazonEC2ContainerRegistryReadOnly"]
    ]
}