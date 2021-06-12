# Configure the AWS Provider
provider "aws" {
    region = "eu-central-1" 
    access_key = #***************************
    secret_key = #***************************
}

# Create vpc 
resource "aws_vpc" "final_project" {
  cidr_block = "10.20.0.0/16" 
}

# Create Internet Gateway
resource "aws_internet_gateway" "gw" {
  vpc_id = aws_vpc.final_project.id
}


# Create Custom Route Table
resource "aws_route_table" "rt" {
  vpc_id = aws_vpc.final_project.id

  route {
    cidr_block = "0.0.0.0/0" 
    gateway_id = aws_internet_gateway.gw.id
  }

  route {
    ipv6_cidr_block = "::/0" 
    gateway_id = aws_internet_gateway.gw.id
  }

  tags = {
    Name = "final_project"
  }
}

# Create a Subnet 

resource "aws_subnet" "fp_subnet" {
  vpc_id            = aws_vpc.final_project.id
  cidr_block        = var.subnets[0] 
  availability_zone = "us-east-1c"  
  tags = {
    Name = "fp_subnet"
  }
}


resource "aws_subnet" "fp_subnet_2" {
  vpc_id            = aws_vpc.final_project.id
  cidr_block        = var.subnets[1] 
  availability_zone = "eu-central-1a"
  tags = {
    Name = "fp_subnet_2"
  }
}

#  Associate subnet with Route Table
resource "aws_route_table_association" "a" {
  subnet_id      = aws_subnet.fp_subnet.id
  route_table_id = aws_route_table.rt.id
}

# Create Security Group to allow port 22,80,443
resource "aws_security_group" "allow_web" {
  name        = "allow_web_traffic"
  description = "Allow Web inbound traffic"
  vpc_id      = aws_vpc.final_project.id

  ingress {
    description = "HTTPS"
    from_port   = 443 
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    description = "HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    description = "docker"
    from_port   = 5000
    to_port     = 5000
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    description = "docker"
    from_port   = 6000
    to_port     = 6000
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    description = "docker"
    from_port   = 7000
    to_port     = 7000
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "allow_web"
  }
}


# Create a network interface with an ip in the subnet that was created
resource "aws_network_interface" "web-server-nic" {
  subnet_id       = aws_subnet.fp_subnet.id
  private_ips     = ["10.20.1.50"]
  security_groups = [aws_security_group.allow_web.id]
}


# Assign an elastic IP to the network interface created
resource "aws_eip" "one" {
  vpc                       = true
  network_interface         = aws_network_interface.web-server-nic.id
  associate_with_private_ip = "10.20.1.50"
  depends_on                = [aws_internet_gateway.gw]
}

output "server_public_ip" {
  value = aws_eip.one.public_ip
}

# Create Ubuntu server and enable apache2
resource "aws_instance" "web-server-instance" {
  ami               = var.image_id[1]     
  instance_type     = "t2.micro"
  availability_zone = "eu-central-1a"
  key_name          = "donia-keys"

  network_interface {
    device_index         = 0
    network_interface_id = aws_network_interface.web-server-nic.id
  }

  user_data = <<-EOF
             #!/bin/bash
                sudo apt update -y
                sudo apt install docker.io -y
                sudo curl -L "https://github.com/docker/compose/releases/download/1.27.4/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
                EOF   
                
  tags = {
    Name = "web-server"
  }
  
   # commands to run after creating the Ubuntu server
  provisioner "remote-exec" {
    # commands to build the python image and run it
    inline = [
      "sudo apt update -y",
      "sudo apt install docker.io -y",
      "sudo curl -L \"https://github.com/docker/compose/releases/download/1.27.4/docker-compose-$(uname -s)-$(uname -m)\" -o /usr/local/bin/docker-compose",
      "sudo chmod +x /usr/local/bin/docker-compose",
      "sudo apt install git-all -y",
      "git clone https://github.com/Donia2610/CurrencyConverter.git",
      "cd CurrencyConvertor",
      "sudo docker-compose up -d --build"
    ]

    # make connection to the Ubuntu server 
    connection {
    type     = "ssh"
    private_key = file("./donia-keys.pem") 
    user     = "ubuntu"
    host     = aws_instance.web-server-instance.public_ip 
    agent = false
    }
  }
  
}

# Create a new load balance
resource "aws_lb" "fp_lb" {
  name               = "final_project"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.allow_web.id]
  subnets            = ["10.20.1.0/24", "10.20.10.0/24"]

  enable_deletion_protection = true

  tags = {
    Environment = "production"
  }
}

# create an aws target group
resource "aws_lb_target_group" "fp_target" {
  name     = "target"
  port     = 5000
  protocol = "HTTP"
  vpc_id   = aws_vpc.final_project.id
}

# connect the lold balncer to the target group 
resource "aws_lb_target_group_attachment" "connection" {
  target_group_arn = aws_lb_target_group.fp_target.arn
  target_id        = aws_instance.web-server-instance.id
  port             = 5000
}
