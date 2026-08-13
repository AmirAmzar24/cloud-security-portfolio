# -- VPC CIDR --
variable "vpc_cidr" {
    description = "CIDR block for the VPC"
    type = string
    default = "10.0.0.0/16"
}

# -- Public Subnet --
variable "public_subnets" {
    description = "Map of AZ -> CIDR for public subnets"
    type = map(string)
    default = {
        "ap-southeast-1a" = "10.0.1.0/24"
        "ap-southeast-1b" = "10.0.3.0/24"
    }
}

# -- Private Subnet --
variable "private_subnets" {
    description = "Map of AZ -> CIDR for private subnets"
    type = map(string)
    default = {
        "ap-southeast-1a" = "10.0.2.0/24"
        "ap-southeast-1b" = "10.0.4.0/24"
    }
}

# -- Project Name --
variable "project_name" {
    description = "Name prefix for tagging resources"
    type = string
    default = "project2"
}