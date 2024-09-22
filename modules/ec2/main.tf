# Create an development EC2 instance that will use the AMI created above.
# Here we needed to setup Docker and a reverse-proxy to serve some dockerized services.
resource "aws_instance" "ec2" {
    instance_type = var.instance_type
    ami           = data.aws_ami.ami.id
    key_name      = var.key_name
    availability_zone = "eu-west-3a"
    user_data = <<-EOF
                    #!/bin/bash

                    cd /home
                    sudo apt-get update
                    sudo apt install -y docker.io
                    sudo groupadd docker
                    sudo gpasswd -a ubuntu docker
                    sudo docker plugin install grafana/loki-docker-driver:latest --alias loki --grant-all-permissions
                    touch Caddyfile
                    echo -e "https://${var.domain_name} {\n\treverse_proxy ${var.service_name}:${var.ec2_ports[0]}\n}\n" >> Caddyfile
                    sudo docker network create caddy
                    sudo docker run -d --restart unless-stopped -p 80:80 -p 443:443 -p 443:443/udp -v $PWD/Caddyfile:/etc/caddy/Caddyfile -v caddy_data:/data -v caddy_config:/config --network caddy --name caddy caddy:latest
                EOF 

    vpc_security_group_ids = [aws_security_group.default.id]
    subnet_id = var.subnet_id

    root_block_device {
        volume_type = "gp2"
        volume_size = 40 // 40GB
    }

    credit_specification {
        cpu_credits = "standard"
    }

    tags = {
        Name = var.ec2_tag
        Team = "Ganarok"
    }
}

resource "aws_route_table" "route-table" {
    vpc_id = var.vpc_id

    route {
        cidr_block = "0.0.0.0/0"
        gateway_id = var.internet_gateway_id
    }

    # tags {
    #     Name = "test-env-route-table"
    # }
}

resource "aws_route_table_association" "subnet-association" {
    subnet_id      = var.subnet_id
    route_table_id = aws_route_table.route-table.id
}

resource "aws_network_interface" "ec2" {
    subnet_id   = var.subnet_id
    private_ips = ["10.0.0.100"]
}

# Create an AMI from the EC2 instance.
data "aws_ami" "ami" {
    most_recent = true
    owners = ["amazon", var.account_id]

    filter {
        name   = "name"
        values = ["ubuntu/images/hvm-ssd/ubuntu-focal-20.04-amd64-server-*"] // Ubuntu 20.04
    }

    filter {
        name   = "virtualization-type"
        values = ["hvm"]
    }

    tags = {
        Name = "${var.ec2_name}-ami"
    }
}

# Create an Elastic IP address and assign it to the ec2 instance.
resource "aws_eip" "ec2_eip" {
    instance = aws_instance.ec2.id
    domain   = "vpc"
}

# Create a default security group for the default VPC.
resource "aws_security_group" "default" {
    vpc_id  = var.vpc_id

    ingress {
        from_port   = 0
        to_port     = 0
        protocol    = "-1"
        cidr_blocks = ["0.0.0.0/0"]
    }

    ingress {
        description = "ssh"
        from_port   = 22
        to_port     = 22
        protocol    = "tcp"
        cidr_blocks = ["0.0.0.0/0"]   
    }

    dynamic "ingress" {
        for_each = toset(var.ec2_ports)

        content {
            description = "http"
            from_port   = ingress.key
            to_port     = ingress.key
            protocol    = "tcp"
            cidr_blocks = ["0.0.0.0/0"]
        }
    }

    egress {
        from_port   = 0
        to_port     = 0
        protocol    = "-1"
        cidr_blocks = ["0.0.0.0/0"]
    }

    tags = {
        Name = "Allow_http_ssh"
    }
}

# resource "aws_route53_record" "live" {
#     zone_id = aws_route53_zone.zone_prod.zone_id
#     name    = "www"
#     type    = "CNAME"
#     ttl     = 5

#     weighted_routing_policy {
#         weight = 90
#     }

#     set_identifier = "live"
#     records        = ["live.example.com"]
# }

# resource "aws_route53_zone" "zone_prod" {
#     name = var.domain_name

#     tags = {
#         Environment = "production"
#     }
# }