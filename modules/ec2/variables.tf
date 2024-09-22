variable "instance_type" {
    type = string
    default = "t2.micro" # Update here the type of instance
    description = "The type of instance to be created"
}

variable "ec2_name" { # Default value for the name of the instance
    type = string
    default = "my-ec2-instance" # Update here the name of the instance
    description = "The name of the EC2 Instance"
}

variable "ec2_tag" {
    type = string
    default = "EC2 Instance" # Update here the name of the instance
    description = "The name of the EC2 Instance"
}

variable "account_id" {
    type = string
    default = "486259851743"
    description = "The AWS account ID"
}

variable "key_name" {
    type = string
    default = "terraform_key"
    description = "The name of the key pair to be used"
}

variable "public_key" {
    type = string
    default = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQCG4DpVBK4CqZ8obwOmHsJoZYv6bnT6rOvG2Y2G0yQaVibJ3C3Rujrjniog7jIUw7GlpBAXjYTvhoC61OZiHyY33o32a+ZV+z/xIiGQU24bqUTvS1dFiFWgf5O7u+vuvKBHg1R7GC85/bthmpllxai08VYHHHbpbKWCErjkcRY/NGcH8vmsxl9shhGw4B2cVaRNOJ19sU2ehs+QGH4CLEaoiXgi/78p82r/j2NKYLYHgVaEloxAIv0lss+VrivxQ+dwDjnoiy6QVyjwhIDk4cXSXZjORtf7ca57OUbWYU3lcko9KhoIrx0wh5qILzABqkAhTvrSbFuN8rR4ielpsxYwRLIbA8q6/5fgjrOjiVMtUd5cP4rIPXbiQ6M0/WMwCkDgqYGAnAIvZkGSDemG5v4Q04iDvGCKMQx48QY/8oOa6tWYAftxuo27S+F1O/NgElzyLbqgSpg/R8jeLVDlX6rZsFpCkwum8WqpZ/wpk/xaK3jeXtihzSw8KhFyxnE4Gwc="
    description = "The name of the key pair to be used"
}

variable "ec2_ports" {
    type = list(number)
    default = [ 3000 ]
    description = "The port to be used"
}

variable "vpc_id" {
    type = string
    description = "The VPC ID"
}

variable "internet_gateway_id" {
    type = string
    description = "The Internet Gateway ID"
}

variable "domain_name" {
    type = string
    description = "The domain name"
}

variable "service_name" {
    type = string
    description = "The service name"
}

variable "subnet_id" {
    type = string
    description = "The subnet ID"
}
