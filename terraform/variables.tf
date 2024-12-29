variable "aws_region" {
  description = "The AWS region to deploy the resources"
  type        = string
  default = "us-east-1"
}

variable "vpc_cidr" {
  type    = string
  default = "10.10.0.0/16"
}

variable "private_subnets" {
  type    = list(string)
  default = [ "10.10.1.0/24", "10.10.2.0/24", "10.10.3.0/24" ]
}

variable "public_subnets" {
  type    = list(string)
  default = [ "10.10.4.0/24", "10.10.5.0/24", "10.10.6.0/24" ]
}

variable "db_username" {
  description = "The username for the PostgreSQL database"
  type        = string
  default = "postgres"
}

variable "db_password" {
  description = "The password for the PostgreSQL database"
  type        = string
  sensitive   = true
}

variable "eks_cluster_name" {
  description = "The name of the EKS cluster"
  type        = string
  default = "shodapp-eks-cluster"
}

variable "eks_node_group_name" {
  description = "The name of the EKS node group"
  type        = string
  default = "shodapp-eks-nodes"
}

variable "eks_node_instance_type" {
  description = "The instance type for the EKS nodes"
  type        = string
  default = "t3.medium"
}

variable "eks_node_desired_size" {
  description = "The desired number of nodes in the EKS node group"
  type        = number
  default = 2
}

variable "eks_node_max_size" {
  description = "The maximum number of nodes in the EKS node group"
  type        = number
  default = 5
}

variable "eks_node_min_size" {
  description = "The minimum number of nodes in the EKS node group"
  type        = number
  default = 1
}

variable "personal_aws_access_key" {
  description = "value of the personal AWS access key"
  type        = string
}

variable "personal_aws_secret_key" {
  description = "value of the personal AWS secret key"
  type       = string
}

variable "zone_id" {
  description = "The Route 53 zone ID"
  type        = string
}

variable "JWT_SECRET_KEY" {
  description = "The secret key for JWT token"
  type        = string
  sensitive   = true
}

variable "SHODAN_API_KEY" {
  description = "The API key for Shodan"
  type        = string
  sensitive   = true
}