module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "19.16.0"

  cluster_name    = var.cluster_name
  cluster_version = var.cluster_version

  cluster_endpoint_private_access = true
  cluster_endpoint_public_access  = true

  cluster_enabled_log_types = [ "audit", "api", "authenticator" , "controllerManager", "scheduler"]
  cloudwatch_log_group_retention_in_days = "7"

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

  vpc_id        = module.vpc.vpc_id
  subnet_ids    = module.vpc.private_subnets

  eks_managed_node_groups = {
    blue = {}
    green = {
      min_size     = 1
      max_size     = 10
      desired_size = 1

      instance_types = var.instance_types
      capacity_type  = var.capacity_type
    }
  }
}

#Cluster aws load balancer addon
module "eks_blueprints_addons" {
  source = "aws-ia/eks-blueprints-addons/aws"
  version = "~> 1.2" #ensure to update this to the latest/desired version

  cluster_name      = module.eks.cluster_name
  cluster_endpoint  = module.eks.cluster_endpoint
  cluster_version   = module.eks.cluster_version
  oidc_provider_arn = module.eks.oidc_provider_arn

  enable_aws_load_balancer_controller    = true
}

#GIT Repo creation
resource "github_repository" "main" {
  name       = var.repository_name
  visibility = "private"
  auto_init  = true
}

resource "github_branch_default" "main" {
  repository = github_repository.main.name
  branch     = "main"
}

resource "tls_private_key" "flux" {
  algorithm   = "ECDSA"
  ecdsa_curve = "P256"
}

resource "github_repository_deploy_key" "this" {
  title      = "Flux"
  repository = github_repository.main.name
  key        = tls_private_key.flux.public_key_openssh
  read_only  = "false"
}

#Flux bootstraping
resource "flux_bootstrap_git" "this" {
  path = "clusters/my-cluster"
  components_extra = ["image-reflector-controller","image-automation-controller"]
}

#IAM role for ECR scaning
resource "aws_iam_role" "ecr-scan-role" {
  name = "ECR-SCAN-ROLE"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Federated = "arn:aws:iam::${var.account_id}:oidc-provider/oidc.eks.${var.region}.amazonaws.com/id/${trimprefix(module.eks.cluster_oidc_issuer_url, "https://oidc.eks.${var.region}.amazonaws.com/id/")}"
        }
        Action = "sts:AssumeRoleWithWebIdentity"
        Condition = {
            "StringEquals" = {
                "oidc.eks.${var.region}.amazonaws.com/id/${trimprefix(module.eks.cluster_oidc_issuer_url, "https://oidc.eks.${var.region}.amazonaws.com/id/")}:sub": "system:serviceaccount:flux-system:ecr-credentials-sync"
                "oidc.eks.${var.region}.amazonaws.com/id/${trimprefix(module.eks.cluster_oidc_issuer_url, "https://oidc.eks.${var.region}.amazonaws.com/id/")}:aud": "sts.amazonaws.com"
            }
        }
      }
    ]
  })
}

resource "aws_iam_policy_attachment" "ecr_readonly_policy_attachment" {
  name = "Policy Attachement"
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
  roles       = [aws_iam_role.ecr-scan-role.name]
}

#IAM role for ClusterAutoscaler
resource "aws_iam_role" "EKSClusterAutoscalerRole" {
  name = "EKSClusterAutoscalerRole"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Federated = "arn:aws:iam::${var.account_id}:oidc-provider/oidc.eks.${var.region}.amazonaws.com/id/${trimprefix(module.eks.cluster_oidc_issuer_url, "https://oidc.eks.${var.region}.amazonaws.com/id/")}"
        }
        Action = "sts:AssumeRoleWithWebIdentity"
        Condition = {
            "StringEquals" = {
                "oidc.eks.${var.region}.amazonaws.com/id/${trimprefix(module.eks.cluster_oidc_issuer_url, "https://oidc.eks.${var.region}.amazonaws.com/id/")}:sub": "system:serviceaccount:kube-system:cluster-autoscaler"
                "oidc.eks.${var.region}.amazonaws.com/id/${trimprefix(module.eks.cluster_oidc_issuer_url, "https://oidc.eks.${var.region}.amazonaws.com/id/")}:aud": "sts.amazonaws.com"
            }
        }
      }
    ]
  })
}

#IAM policy for ClusterAutoscaler

resource "aws_iam_policy" "EKSClusterAutoscalerPolicy" {
  name        = "EKSClusterAutoscalerPolicy"
  
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "autoscaling:DescribeAutoScalingGroups",
                "autoscaling:DescribeAutoScalingInstances",
                "autoscaling:DescribeLaunchConfigurations",
                "autoscaling:DescribeTags",
                "autoscaling:SetDesiredCapacity",
                "autoscaling:TerminateInstanceInAutoScalingGroup",
                "ec2:DescribeLaunchTemplateVersions"
        ]
        Effect   = "Allow"
        Resource = "*"
      },
    ]
  })
}

resource "aws_iam_role_policy_attachment" "AmazonEKSClusterAutoscaler" {
  role       = aws_iam_role.EKSClusterAutoscalerRole.name
  policy_arn = aws_iam_policy.EKSClusterAutoscalerPolicy.arn
}