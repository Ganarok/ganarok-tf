output "EC2_IP" {
    description = "Public Server IP"
    value       = aws_eip.ec2_eip.public_ip
    sensitive   = false
}
