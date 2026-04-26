module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "19.21.0"  

  # Original parameter names work with 19.x
  cluster_name    = local.name
  cluster_version = "1.28"

  cluster_endpoint_public_access       = true
  cluster_endpoint_public_access_cidrs = ["0.0.0.0/0"]

  cluster_addons = {
    coredns = {
      most_recent = true
    }
    kube-proxy = {
      most_recent = true
    }
    vpc-cni = {
      most_recent = true
    }
  }

  vpc_id     = module.vpc.vpc_id
  subnet_ids = module.vpc.private_subnets

  eks_managed_node_groups = {
    worker_node = {
      min_size     = 2
      max_size     = 4
      desired_size = 2

      instance_types = ["t3.small"]   # 2 vCPU, 2 GB RAM
      capacity_type  = "ON_DEMAND"    

      tags = {
        ExtraTag = "Worker_Node"
      }
    }
  }

  tags = local.tags
}
