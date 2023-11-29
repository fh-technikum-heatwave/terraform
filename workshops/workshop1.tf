# Specifies the AWS provider and the region where to create the resources
provider "aws" {
  region = "us-east-1"
}

# Create a default VPC (in the previously specified region)
resource "aws_default_vpc" "default" {}

# Create a security group for the web server
resource "aws_security_group" "web_sg" {
  name        = "web_sg"
  description = "Security group for web server"
  
  # Ingress rule allows incoming traffic on port 80 from any IP 
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Egress rule allows all outbound traffic (all ports and protocols)
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# Create and EC2 instance (web server)
resource "aws_instance" "web_server" {
  ami           = "ami-0fc5d935ebf8bc3bc"  # uses the ubuntu machine image
  instance_type = "t2.micro" # type of instance
  key_name      = "vockey" # use lab ssh key
  
  # Attach the created security group to the EC2 instance
  vpc_security_group_ids = [aws_security_group.web_sg.id]
  
  # Script that will be executed during instance start, installing Apache
  user_data = <<-EOF
              #!/bin/bash
              sudo apt-get update
              sudo apt-get install -y apache2
              sudo systemctl start apache2
              sudo systemctl enable apache2
              echo "<h1>Hello World</h1>" | sudo tee /var/www/html/index.html
              EOF

  # Associates a plublic IP with the EC2 instance
  associate_public_ip_address = true
}

# Output the public DNS of the created EC2 instance
output "public_dns" {
  value = aws_instance.web_server.public_dns
}
