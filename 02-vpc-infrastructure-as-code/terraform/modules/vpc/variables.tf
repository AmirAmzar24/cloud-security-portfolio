variable "vpc_cidr" {
  description = "CIDR block for the VPC"
  type        = string
}

variable "public_subnets" {
  description = "Map of AZ -> CIDR for public subnets"
  type        = map(string)
}

variable "private_subnets" {
  description = "Map of AZ -> CIDR for private subnets"
  type        = map(string)
}

variable "project_name" {
  description = "Name prefix for tagging resources"
  type        = string
}
