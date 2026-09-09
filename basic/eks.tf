## 클러스터 생성
locals {
  eks_information = try(var.eks_information.create, false) ? {
    "eks" = merge(
      try(var.eks_information, {}),
      {
        subnet_list = [
          for k, v in local.subnet_with_az_map : aws_subnet.this[k].id
          if startswith(k, "pri-eks")
        ]
      }
    )
  } : {} 
}

resource "aws_eks_cluster" "eks_cluster" {
    for_each = local.eks_information

    name = each.value.name 
    role_arn = aws_iam_role.eks_cluster["eks_cluster_role"].arn 
    version = each.value.k8s_version

    access_config {
        authentication_mode = each.value.authentication_mode
    }

    vpc_config {
        subnet_ids = each.value.subnet_list 
        endpoint_private_access = each.value.private_access
        endpoint_public_access = each.value.public_access
    }

    depends_on = [
        aws_iam_role_policy_attachment.eks_cluster_policy["eks_cluster_role"]
    ]

    tags = each.value.tags

}


## EKS 내 Access 추가 
locals {
  eks_entry_access = var.eks_information.create == true ? merge(
    var.eks_entry_access,
    {
      "bastion" = {
        principal = aws_iam_role.bastion_eks_role.arn
        type = "STANDARD"
        policy_arn = "AmazonEKSClusterAdminPolicy"
        access_scope_type = "cluster"
      }
    }
  ) : {}
}

resource "aws_eks_access_entry" "this" {
  for_each = local.eks_entry_access

  cluster_name      = aws_eks_cluster.eks_cluster["eks"].name 
  principal_arn     = each.value.principal
  type              = each.value.type
}

resource "aws_eks_access_policy_association" "this" {
  for_each = local.eks_entry_access

  cluster_name  = aws_eks_cluster.eks_cluster["eks"].name
  policy_arn    = "arn:aws:eks::aws:cluster-access-policy/${each.value.policy_arn}"
  principal_arn = each.value.principal

  access_scope {
    type       = each.value.access_scope_type
    namespaces = lookup(each.value, "namespace", null)
  }
}


## Node Group 생성
locals {
  node_group_information = var.eks_information.create == true ? var.eks_node_groups : {}
}

resource "aws_eks_node_group" "node_group" {
  for_each = local.node_group_information

  cluster_name = aws_eks_cluster.eks_cluster["eks"].name 
  node_role_arn = aws_iam_role.eks_node["node_group_role"].arn 
  subnet_ids = [
    for k, v in local.subnet_with_az_map : aws_subnet.this[k].id 
    if startswith(k, "pri-eks")
  ]

  node_group_name = split("_", each.key)[0]

  instance_types = each.value.instance_type 
  disk_size = each.value.disk_size
  capacity_type = each.value.capacity_type

  scaling_config {
    desired_size = each.value.desired_size
    min_size = each.value.min_size
    max_size = each.value.max_size    
  }

  depends_on = [
    aws_iam_role_policy_attachment.node_group_policy["AmazonEC2ContainerRegistryReadOnly"],
    aws_iam_role_policy_attachment.node_group_policy["AmazonEKSWorkerNodePolicy"],
    aws_iam_role_policy_attachment.node_group_policy["AmazonEKS_CNI_Policy"]
  ]
}

## EKS AddOn 추가
locals{
  addon_list = var.eks_information.create == true ? {
    for addon, version in var.eks_information.addon_list : addon => {
      type = ( addon == "coredns" ) ? "deployment" : "daemonset"
      version = version
    }
  } : {}
  
  deploy_addon_config = jsonencode({
    replicaCount = 2
    topologySpreadConstraints = [
      {
        maxSkew = 1
        topologyKey = "kubernetes.io/hostname"
        whenUnsatisfiable = "ScheduleAnyway"
      }
    ]
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
  })
}


resource "aws_eks_addon" "this" {
  for_each = local.addon_list

  cluster_name = aws_eks_cluster.eks_cluster["eks"].name
  addon_name = each.key
  # addon_version을 명시하지 않을 경우, 해당 EKS 버전의 권장 최신 버전 설치 
  addon_version = each.value.version
  resolve_conflicts_on_create = "OVERWRITE"
  resolve_conflicts_on_update = "OVERWRITE"


  configuration_values = (each.value.type == "deployment" ) ? local.deploy_addon_config : null 
}


## kubectl 사용을 위해 생성된 EKS의 보안 그룹 정보를 가져와 bastion에 있는 보안 그룹 추가
locals {
  eks_cluster_information = var.eks_information.create == true ? {
    "for_kubectl" = {
      security_group_id = aws_eks_cluster.eks_cluster["eks"].vpc_config[0].cluster_security_group_id
      type = "ingress"
      from_port = 443 
      to_port = 443 
      protocol = "tcp" 
      source_security_group_id = aws_security_group.pub-bastion.id
    }
  } : {}
}

resource "aws_security_group_rule" "eks_bastion_kubectl" {
  for_each = local.eks_cluster_information

  security_group_id = each.value.security_group_id
  type = each.value.type 
  from_port = each.value.from_port
  to_port = each.value.to_port 
  protocol = each.value.protocol 
  source_security_group_id = each.value.source_security_group_id
}


