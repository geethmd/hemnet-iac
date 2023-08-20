provider "aws" {
  region = var.region
}

terraform {
  required_version = ">=1.1.5"

  required_providers {
    aws = {
      source = "hashicorp/aws"
      version = "5.12.0"
    }
    flux = {
      source  = "fluxcd/flux"
      version = "1.0.1"
    }
    github = {
      source  = "integrations/github"
      version = ">=5.18.0"
    }
  } 
}

provider "github" {
  owner = var.github_org
  token = var.github_token
}

provider "flux" {
  kubernetes = {
    host                   = module.eks.cluster_endpoint
    cluster_ca_certificate = base64decode(module.eks.cluster_certificate_authority_data)
    exec ={
        api_version = "client.authentication.k8s.io/v1beta1"
        command     = "aws"
        args = ["eks", "get-token", "--cluster-name", var.cluster_name]
    }
  }
  git = {
    url = "ssh://git@github.com/geethmd/${github_repository.main.name}.git"
    ssh = {
      username    = "git"
      private_key = tls_private_key.flux.private_key_pem
    }
  }
}

provider "helm" {
  kubernetes {
    host                   = module.eks.cluster_endpoint
    cluster_ca_certificate = base64decode(module.eks.cluster_certificate_authority_data)
    exec {
      api_version = "client.authentication.k8s.io/v1beta1"
      command = "aws"
      args = [
        "eks",
        "get-token",
        "--cluster-name",
        var.cluster_name
      ]
    }
  }
}