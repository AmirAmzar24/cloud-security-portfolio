# outputs.tf — values exposed after `apply` (view with `terraform output`).

output "vpc_id" {
  description = "ID of the VPC"
  value       = module.vpc.vpc_id
}

output "public_subnet_ids" {
  description = "Map of AZ -> public subnet ID"
  value       = module.vpc.public_subnet_ids
}

output "private_subnet_ids" {
  description = "Map of AZ -> private subnet ID"
  value       = module.vpc.private_subnet_ids
}

output "internet_gateway_id" {
  description = "ID of the Internet Gateway"
  value       = module.vpc.internet_gateway_id
}

output "web_sg_id" {
  description = "ID of the web-tier security group"
  value       = module.vpc.web_sg_id
}

output "db_sg_id" {
  description = "ID of the database security group"
  value       = module.vpc.db_sg_id
}
