output "vpc_id" {
  description = "ID of the VPC"
  value       = aws_vpc.main_vpc.id
}

output "public_subnet_id" {
  description = "ID of the public subnet"
  value       = aws_subnet.public_subnet.id
}

output "private_subnet_id" {
  description = "ID of the private subnet"
  value       = aws_subnet.private_subnet.id
}

output "internet_gateway_id" {
  description = "ID of the Internet Gateway"
  value       = aws_internet_gateway.igw.id
}

output "web_sg_id" {
  description = "ID of the web-tier security group"
  value       = aws_security_group.web_sg.id
}

output "db_sg_id" {
  description = "ID of the database security group"
  value       = aws_security_group.db_sg.id
}
