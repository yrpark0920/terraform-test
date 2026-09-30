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


############################# Add AddOn #############################
locals {
    controller_configuration_values = jsonencode({
    controller = {
      resources = {
        limits = {
          cpu    = "100m"
          memory = "150Mi"
        }
        requests = {
          cpu    = "100m"
          memory = "150Mi"
        }
      }
    }
  })

    default_configuration_values = jsonencode({
    resources = {
      limits = {
        cpu    = "200m"
        memory = "256Mi"
      }
      requests = {
        cpu    = "100m"
        memory = "128Mi"
      }
    }
  })

    ## Addon별로 configuration 매핑 Map (최종)
    addon_config_map = {
        "vpc-cni" = local.default_configuration_values
        "kube-proxy" = local.default_configuration_values
        "coredns" = local.default_configuration_values
        "aws-ebs-csi-driver" = local.controller_configuration_values
    }

    ## Addon별로 configuration 항목 추가 
    cluster_addons = {
        for k,v in var.cluster_addons : k => merge(v, {
            configuration_values = lookup(local.addon_config_map, k, null)
        })
    }
}

resource "aws_eks_addon" "this" {
    for_each = local.cluster_addons

    cluster_name = aws_eks_cluster.this.name 
    addon_name = each.key 
    addon_version = each.value.version 
    resolve_conflicts_on_create = "OVERWRITE"
    resolve_conflicts_on_update = "OVERWRITE"

    service_account_role_arn = try(aws_iam_role.eks_addon[each.key].arn, null)

    configuration_values = each.value.configuration_values
}

############################# Add Access #############################
/*
> module.dev_eks.result
{
  "yrpark@ensmart.co.kr" = {
    "policy" = "AmazonEKSAdminViewPolicy"
    "target" = "arn:aws:iam::024732177529:user/yrpark@ensmart.co.kr"
  }
}
*/
locals {
    eks_admin_policy_target = {
        for target in var.eks_console_access : target => {
            target = (strcontains(target, "@")) ? "arn:aws:iam::024732177529:user/${target}" : "arn:aws:iam::024732177529:role/${target}"
            policy = "AmazonEKSAdminViewPolicy"
        }
    }   

    eks_access_information = merge(local.eks_admin_policy_target, {})
}

resource "aws_eks_access_entry" "this" {
    for_each = local.eks_access_information

    cluster_name = aws_eks_cluster.this.name 
    principal_arn = each.value.target
    type = "STANDARD"
}

resource "aws_eks_access_policy_association" "this" {
    for_each = local.eks_access_information

    cluster_name = aws_eks_cluster.this.name 
    policy_arn = "arn:aws:eks::aws:cluster-access-policy/${each.value.policy}"
    principal_arn = aws_eks_access_entry.this[each.key].principal_arn

    access_scope {
        type = "cluster" # namespace 또는 cluster만 가능 
    }
}