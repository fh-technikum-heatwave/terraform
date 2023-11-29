# Configure AWS as the cloud provider and set region where resources should be created
provider "aws" {
  region = "us-east-1"
}

# Create a virtual private cloud with the cidr block 10.0.0.0/16
resource "aws_vpc" "vpc" {
  cidr_block = "10.0.0.0/16"
}

# Creates a internet gateway and associates it with the VPC
resource "aws_internet_gateway" "gw" {
  vpc_id = aws_vpc.vpc.id
}

# Creates a route table and associates it with the VPC
resource "aws_route_table" "route_table" {
  vpc_id = aws_vpc.vpc.id

  # Adds a default route to the internet gateway
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.gw.id
  }
}

# Creates a subnet in the VPC with the CIDR block 10.0.1.0/24
resource "aws_subnet" "subnet" {
  vpc_id     = aws_vpc.vpc.id
  cidr_block = "10.0.1.0/24"
}

# Associate the subnet with the route table
resource "aws_route_table_association" "a" {
  subnet_id      = aws_subnet.subnet.id
  route_table_id = aws_route_table.route_table.id
}

# Create a security group
resource "aws_security_group" "sg" {
  name        = "allow_web"
  description = "Allow web inbound traffic"
  vpc_id      = aws_vpc.vpc.id 

  # Allow inbound traffic on port 80 from all IPs
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Allow all outbound traffic
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# Allocate an Elastic IP
resource "aws_eip" "eip" { 
  vpc = true
}

# Create a network interface with a private IP address and associate it with the subnet and security group
resource "aws_network_interface" "private_ip" {
  subnet_id       = aws_subnet.subnet.id
  private_ips     = ["10.0.1.50"]
  security_groups = [aws_security_group.sg.id]
}

# Associate the allocated Elastic IP with the created network interface
resource "aws_eip_association" "eip_assoc" {
  allocation_id        = aws_eip.eip.id
  network_interface_id = aws_network_interface.private_ip.id
}

# Create a EC2 instance
resource "aws_instance" "app" {
  ami           = "ami-0fc5d935ebf8bc3bc" # Use the Ubuntu machine image
  instance_type = "t2.micro" # type of machine

  # Associate the machine with the created network interface
  network_interface {
    device_index          = 0
    network_interface_id  = aws_network_interface.private_ip.id
  }

  # Script that will be executed during instance start, installing Apache
  user_data = <<-EOF
                #!/bin/bash
                sudo apt-get update
                sudo apt-get install -y apache2
                sudo systemctl start apache2
                sudo systemctl enable apache2
                echo "<h1>Hello World</h1>" | sudo tee /var/www/html/index.html
                EOF

  # Tags the instance
  tags =  {
    Name = "app_server"
  }
}


# Outputs the public ip
output "public_ip" {
  value = aws_instance.app.public_ip
}
