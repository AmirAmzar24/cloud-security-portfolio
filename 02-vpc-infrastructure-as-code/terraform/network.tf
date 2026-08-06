# -- VPC -- 
resource "aws_vpc" "main_vpc" {
    cidr_block = "10.0.0.0/16"
    tags = {
        Name = "project2-vpc"
    }
}

# -- Public Subnet --
resource "aws_subnet" "public_subnet" {
    vpc_id = aws_vpc.main_vpc.id
    cidr_block = "10.0.1.0/24"
    availability_zone = "ap-southeast-1a"
    map_public_ip_on_launch = true
    tags = {
        Name = "project2-public"
    }
}

# -- Private Subnet --
resource "aws_subnet" "private_subnet" {
    vpc_id = aws_vpc.main_vpc.id
    cidr_block = "10.0.2.0/24"
    availability_zone = "ap-southeast-1a"
    tags = {
        Name = "project2-private"
    }
}

# -- Internet Gateway --
resource "aws_internet_gateway" "igw" {
    vpc_id = aws_vpc.main_vpc.id
    tags = {
        Name = "project2-igw"
    }
}

# -- Public Subnet Route Table --
resource "aws_route_table" "public_rt" {
    vpc_id = aws_vpc.main_vpc.id
    route {
        cidr_block = "0.0.0.0/0"
        gateway_id = aws_internet_gateway.igw.id
    }
    tags = {
        Name = "project2-public-rt"
    }
}

# -- Public Subnet RT Association --
resource "aws_route_table_association" "public_assoc" {
    subnet_id = aws_subnet.public_subnet.id
    route_table_id = aws_route_table.public_rt.id
}

# -- Web Server SG --
resource "aws_security_group" "web_sg" {
    vpc_id = aws_vpc.main_vpc.id
    description = "Web Server SG for project2 VPC"
    ingress {
        from_port = 443
        to_port = 443
        protocol = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }
    egress {
        from_port = 0
        to_port = 0
        protocol = "-1"
        cidr_blocks = ["0.0.0.0/0"]
    }
}

# -- DB Server SG --
resource "aws_security_group" "db_sg" {
    vpc_id = aws_vpc.main_vpc.id
    description = "DB Server SG for project2 VPC"
    ingress {
        from_port = 3306
        to_port = 3306
        protocol = "tcp"
        security_groups = [aws_security_group.web_sg.id]
    }
    egress {
        from_port = 443
        to_port = 443
        protocol = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }
}

/*
# DONT RUN TERRAFORM APPLY ONLY TERRAFORM PLAN NAT GATEWAY IS NOT FREE
# -- NAT Gateway EIP -- 
resource "aws_eip" "nat_eip" {
    domain = "vpc"
    tags = {
        Name = "project2-nat-eip"
    }
}

# -- NAT Gateway --
resource "aws_nat_gateway" "nat" {
    allocation_id = aws_eip.nat_eip.id 
    subnet_id = aws_subnet.public_subnet.id
    depends_on = [aws_internet_gateway.igw]
    tags = {
        Name = "project2-nat"
    }
}

# -- Private Subnet Route Table --
resource "aws_route_table" "private_rt" {
    vpc_id = aws_vpc.main_vpc.id
    route {
        cidr_block = "0.0.0.0/0"
        nat_gateway_id = aws_nat_gateway.nat.id
    }
    tags = {
        Name = "project2-private-rt"
    }
}

# -- Private Subnet RT Association --
resource "aws_route_table_association" "private_assoc" {
    subnet_id = aws_subnet.private_subnet.id
    route_table_id = aws_route_table.private_rt.id
}
*/