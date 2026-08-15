# -- VPC -- 
resource "aws_vpc" "main_vpc" {
    #checkov:skip=CKV2_AWS_11:VPC flow logs are deferred to Project 5 (centralized logging)
    cidr_block = var.vpc_cidr
    tags = {
        Name = "${var.project_name}-vpc"
    }
}

# -- Public Subnet --
resource "aws_subnet" "public_subnet" {
    #checkov:skip=CKV_AWS_130:Public subnets must auto-assign public IPs by design
    for_each = var.public_subnets
    vpc_id = aws_vpc.main_vpc.id
    cidr_block = each.value
    availability_zone = each.key
    map_public_ip_on_launch = true
    tags = {
        Name = "${var.project_name}-public-${each.key}"
    }
}

# -- Private Subnet --
resource "aws_subnet" "private_subnet" {
    for_each = var.private_subnets
    vpc_id = aws_vpc.main_vpc.id
    cidr_block = each.value
    availability_zone = each.key
    tags = {
        Name = "${var.project_name}-private-${each.key}"
    }
}

# -- Internet Gateway --
resource "aws_internet_gateway" "igw" {
    vpc_id = aws_vpc.main_vpc.id
    tags = {
        Name = "${var.project_name}-igw"
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
        Name = "${var.project_name}-public-rt"
    }
}

# -- Public Subnet RT Association --
resource "aws_route_table_association" "public_assoc" {
    for_each = aws_subnet.public_subnet
    subnet_id = each.value.id
    route_table_id = aws_route_table.public_rt.id
}

# -- Public Subnet NACL --
resource "aws_network_acl" "public" {
    #checkov:skip=CKV_AWS_231:Ephemeral port range (1024-65535) required for stateless return traffic; SG is the primary control
    #checkov:skip=CKV2_AWS_1:False positive - NACL is attached via inline subnet_ids; Checkov only detects separate aws_network_acl_association resources
    vpc_id = aws_vpc.main_vpc.id
    subnet_ids = [for s in aws_subnet.public_subnet : s.id]
    ingress {
        rule_no = 100
        action = "allow"
        protocol = "tcp"
        from_port = 443
        to_port = 443
        cidr_block = "0.0.0.0/0"
    }

    ingress {
        rule_no = 110
        action = "allow"
        protocol = "tcp"
        from_port = 1024
        to_port = 65535
        cidr_block = "0.0.0.0/0"
    }

    egress {
        rule_no = 100
        action = "allow"
        protocol = "-1"
        from_port = 0
        to_port = 0
        cidr_block = "0.0.0.0/0"
    }

    tags = {
        Name = "${var.project_name}-public-nacl"
    }
}

# -- Lock Down Default SG (Deny All) --
resource "aws_default_security_group" "default" {
    vpc_id = aws_vpc.main_vpc.id
    #no ingress/egress blocks = allow nothing
}

# -- Web Server SG --
resource "aws_security_group" "web_sg" {
    #checkov:skip=CKV2_AWS_5:No EC2 instances in this lab; SG intentionally unattached (empty scaffold)
    #checkov:skip=CKV_AWS_382:Web tier legitimately needs broad outbound access
    vpc_id = aws_vpc.main_vpc.id
    description = "Web Server SG for project2 VPC"
    ingress {
        description = "Allow HTTPS from the internet"
        from_port = 443
        to_port = 443
        protocol = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }
    egress {
        description = "Allow all outbound"
        from_port = 0
        to_port = 0
        protocol = "-1"
        cidr_blocks = ["0.0.0.0/0"]
    }
}

# -- DB Server SG --
resource "aws_security_group" "db_sg" {
    #checkov:skip=CKV2_AWS_5:No EC2 instances in this lab; SG intentionally unattached (empty scaffold)
    vpc_id = aws_vpc.main_vpc.id
    description = "DB Server SG for project2 VPC"
    ingress {
        description = "Allow MySQL from web tier only"
        from_port = 3306
        to_port = 3306
        protocol = "tcp"
        security_groups = [aws_security_group.web_sg.id]
    }
    egress {
        description = "Allow HTTPS outbound"
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
        Name = "${var.project_name}-nat-eip"
    }
}

# -- NAT Gateway --
resource "aws_nat_gateway" "nat" {
    allocation_id = aws_eip.nat_eip.id 
    subnet_id = aws_subnet.public_subnet.id
    depends_on = [aws_internet_gateway.igw]
    tags = {
        Name = "${var.project_name}-nat"
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
        Name = "${var.project_name}-private-rt"
    }
}

# -- Private Subnet RT Association --
resource "aws_route_table_association" "private_assoc" {
    subnet_id = aws_subnet.private_subnet.id
    route_table_id = aws_route_table.private_rt.id
}
*/

# -- Private Subnet Route Table (for S3 Endpoint) --
resource "aws_route_table" "private_rt" {
    vpc_id = aws_vpc.main_vpc.id
    tags = {
        Name = "${var.project_name}-private-rt"
    }
}

# -- Private Subnet RT Association --
resource "aws_route_table_association" "private_assoc" {
    for_each = aws_subnet.private_subnet
    subnet_id = each.value.id
    route_table_id = aws_route_table.private_rt.id
}

# -- S3 Gateway Endpoint --
resource "aws_vpc_endpoint" "s3_vpc_endpoint" {
    vpc_id = aws_vpc.main_vpc.id
    service_name = "com.amazonaws.ap-southeast-1.s3"
    vpc_endpoint_type = "Gateway"
    route_table_ids = [aws_route_table.private_rt.id]
    tags = {
        Name = "${var.project_name}-s3-endpoint"
    }
}