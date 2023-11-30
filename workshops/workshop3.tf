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
    cidr_blocks = ["0.0.0.0/0"]#allows trafic from all IP
  }

  # Allow all outbound traffic
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1" #allows all outboud traffic, regardless of the protocol
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# Allocate an Elastic IP
resource "aws_eip" "eip" { 
  vpc = true
}


#allocate a second elastic ip for the second instance
resource "aws_eip" "eip2" { 
  vpc = true
}


# Create a network interface with a private IP address and associate it with the subnet and security group
resource "aws_network_interface" "private_ip" {
  subnet_id       = aws_subnet.subnet.id
  private_ips     = ["10.0.1.50"]
  security_groups = [aws_security_group.sg.id]
}


# Create a secon network interface with a private IP address and associate it with the subnet and security group
# Each newtwork_interface can only be used for one intance, multiple instances cannot use the same network_interface
resource "aws_network_interface" "private_ip_2" {
  subnet_id       = aws_subnet.subnet.id
  private_ips     = ["10.0.1.51"]
  security_groups = [aws_security_group.sg.id]
}

# Associate the allocated Elastic IP with the created network interface
resource "aws_eip_association" "eip_assoc" {
  allocation_id        = aws_eip.eip.id
  network_interface_id = aws_network_interface.private_ip.id
}

# Associate the 2nd allocated Elastic IP with the created network interface
resource "aws_eip_association" "eip_assoc2" {
  allocation_id        = aws_eip.eip2.id
  network_interface_id = aws_network_interface.private_ip_2.id
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
                echo "<h1>Hello World 1</h1>" | sudo tee /var/www/html/index.html
                EOF

  # Tags the instance
  tags =  {
    Name = "app_server"
  }
}

# Create a 2nd EC2 instance
resource "aws_instance" "app2" {
  ami           = "ami-0fc5d935ebf8bc3bc" # Use the Ubuntu machine image
  instance_type = "t2.micro" # type of machine

  # Associate the machine with the created network interface
  network_interface {
    device_index          = 0
    network_interface_id  = aws_network_interface.private_ip_2.id
  }

  # Script that will be executed during instance start, installing Apache
  user_data = <<-EOF
                #!/bin/bash
                sudo apt-get update
                sudo apt-get install -y apache2
                sudo systemctl start apache2
                sudo systemctl enable apache2
                echo "<h1>Hello World 2</h1>" | sudo tee /var/www/html/index.html
                EOF

  # Tags the instance
  tags =  {
    Name = "app_server2"
  }
}

#creating a load-balancer with the name "load-balancer"
resource "aws_elb" "load-balancer" {
  name               = "load-balancer"
  subnets            = [aws_subnet.subnet.id] #associates with the subnet specified above
  security_groups    = [aws_security_group.sg.id]# associate the security group specified above

//listener which listens on port 80 for http traffic, forwards it to the instances on port 80
  listener {
    instance_port     = 80
    instance_protocol = "http"
    lb_port           = 80
    lb_protocol       = "http"
  }


  instances                     = [aws_instance.app.id, aws_instance.app2.id] #distributes the incoming traffic on one this 2 specified instancs
  cross_zone_load_balancing     = true # 
  idle_timeout                  = 400
  connection_draining           = true
  connection_draining_timeout   = 400

  tags = {
    Name = "aws_elb" #adds a tag to the load-balancer
  }
}


# Outputs the public ip
output "public_ip" {
  value = aws_instance.app.public_ip
}

# outputs the dns of the load-balancer
output "lb-dns" {
  value = aws_elb.load-balancer.dns_name
}