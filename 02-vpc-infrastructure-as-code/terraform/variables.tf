# -- VPC CIDR --
variable "vpc_cidr" {
    description = "CIDR block for the VPC"
    type = string
    default = "10.0.0.0/16"
}

# -- Public Subnet CIDR --
variable "public_subnet_cidr" {
    description = "CIDR block for public subnet"
    type = string
    default = "10.0.1.0/24"
}

# -- Private Subnet CIDR --
variable "private_subnet_cidr" {
    description = "CIDR block for private subnet"
    type = string
    default = "10.0.2.0/24"
}

# -- AZ --
variable "availability_zone" {
    description = "Availability zone for the subnet"
    type = string
    default = "ap-southeast-1a"
}

# -- Project Name --
variable "project_name" {
    description = "Name prefix for tagging resources"
    type = string
    default = "project2"
}