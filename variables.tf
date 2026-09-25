variable "aws_region" {
  description = "AWS region where resources will be deployed"
  type        = string
  default     = "us-east-1"
}

variable "environment" {
  description = "Deployment environment"
  type        = string
  default     = "dev"
}
variable "project_name" {
  description = "capstone"
  type = string
  default = "my-project"
}
variable "vpc_cidr" {
  description = "The CIDR block for the VPC"
  type = string
  default = "10.0.0.0/16"
}
variable "app_name" {
  description = "The name of the application"
  type = string
  default = "my-app"
}
variable "node_instance_type" {
  description = "EC2 instance type for the EKS worker nodes"
  type = string
  default = "t3.micro"
}
variable "cluster_name" {
  description = "The name of the EKS cluster"
  type = string
  default = "my-eks-cluster"
}
variable "node_count" {
  description = "Number of Kubernetes worker nodes"
  type        = number
  default     = 2
}