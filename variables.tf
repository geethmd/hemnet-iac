#General configuration
variable "region" {
  description = "AWS region"
  type        = string
  default     = "eu-west-1"
}

variable "account_id" {
  description = "AWS Account ID"
  type        = string
  default     = "746247950449"
}

#VPC configuration
variable "vpc_name"{
  description = "VPC name"
  type = string
  default = "nginx-vpc"
}

variable "vpc_cidr"{
  description = "VPC CIDR"
  type = string
  default = "10.3.0.0/16"
}

variable "availability_zone" {
  description = "availability zones"
  type        = list(any)
  default     = ["eu-west-1a", "eu-west-1b"]
}

variable "private_subnets" {
  description = "private subnets"
  type        = list(any)
  default     = ["10.3.1.0/24", "10.3.2.0/24"]
}

variable "public_subnets" {
  description = "public subnets"
  type        = list(any)
  default     = ["10.3.101.0/24", "10.3.102.0/24"]
}

variable "vpc_tags" {
  type = map(string)
  default = {
    Environment = "dev"
    Application = "nginx"
  }
}

#EKS configuration
variable "cluster_name"{
  description = "EKS Cluster name"
  type = string
  default = "nginx-cluster"
}

variable "cluster_version"{
  description = "Flux repo name"
  type = string
  default = "1.27"
}

variable "repository_name"{
  description = "Flux repo name"
  type = string
  default = "fluxcd"
}

variable "instance_types"{
  description = "instance types"
  type    = list(any)
  default = ["t3.small"]
}

variable "capacity_type"{
  description = "capacity types"
  type    = string
  default = "ON_DEMAND"
}

variable "github_token" {
  description = "github_token"
  sensitive = true
  type      = string
}

variable "github_org" {
  description = "github_org"
  type = string
}