# ==========VPC==========
env        = "dev"
vpc_name   = "yrpark-test-vpc"
vpc_cidr   = "10.0.0.0/16"

subnet_newbits = 8
subnet_azs = ["a", "c", "b"]

subnet_lists = {
  "pub-nat" = [0, 1]
  "pri-app" = [2, 3]
  "pri-eks" = [4, 5]
  "pri-db"  = [6, 7, 8]
}

nat = {
  create = true
  subnet = "pub-nat"
  per_az = true
}

# ==========EC2==========
enable_bastion = {
  create = true
  per_az = true
}

# ==========ALB==========
bastion_lb = {
  create = true
  type = public
}

# ==========RDS==========
rds_information = {
  create = true 
  replica = true
  identifier = "dev-rds"
  engine = "mysql"
  engine_version = "8.0"
  allocated_storage = 20
  db_name = "yrpark_db"
  username = "yrpark"
  password = "!Yrpark0920"
  instance_class = "db.t3.micro" 
}

# ==========EKS==========
eks_information = {
  create = true
  name = "yrpark-eks-cluster"
  authentication_mode = "API_AND_CONFIG_MAP"
  k8s_version = "1.35"
  private_access = true 
  public_access = false 
  tags = {
    CreateBy = "Terraform"
  }
  addon_list = {
    "coredns" = "v1.14.3-eksbuild.14"
    "kube-proxy" = "v1.35.3-eksbuild.21"
    "vpc-cni" = "v1.23.0-eksbuild.1"
  }
}

eks_node_groups = {
  "app_node" = {
    instance_type = ["t3.large"]
    disk_size = 30
    min_size = 1 
    max_size = 3
    desired_size = 1
    capacity_type = "ON_DEMAND"
    labels = {
      node-group = "app"
    }
  }
  "mgmt_node" = {
    instance_type = ["t3.medium"]
    disk_size = 20 
    min_size = 1
    max_size = 2 
    desired_size = 1
    capacity_type = "ON_DEMAND"
    labels = {
      node-group = "mgmt"
    }
  }
}

eks_cluster_role_information = {
  name = "yrpark-eks-cluster-role"
  policy = "AmazonEKSClusterPolicy"
  tags = {
    CreatedBy = "Terraform" 
    description = "Using for Create EKS Cluster"
  }
}


eks_node_group_role_information = {
  name = "yrpark-eks-node-role"
  policy = ["AmazonEC2ContainerRegistryReadOnly", "AmazonEKS_CNI_Policy", "AmazonEKSWorkerNodePolicy"]
  tags = {
    CreatedBy = "Terraform"
    description = "Using for Node Group"
  }
}

eks_entry_access = {
  "yrpark" = {
    principal = "arn:aws:iam::024732177529:user/yrpark@ensmart.co.kr"
    type = "STANDARD"
    policy_arn = "AmazonEKSClusterAdminPolicy"
    access_scope_type = "cluster"
  }
}