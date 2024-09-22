################################################################################
# TERRAFORM MAIN FILE
################################################################################

provider "aws" {
    region = "eu-west-3"
}

# Create a new key pair for SSH access to any instance.
resource "aws_key_pair" "key" {
    key_name = var.key_name
    public_key = var.public_key
}

################################################################################
# Instance EC2
################################################################################

# Create a default VPC.
resource "aws_vpc" "default" {
    cidr_block           = "10.0.0.0/16"
    enable_dns_hostnames = true
    enable_dns_support   = true
}

resource "aws_internet_gateway" "igw" {
    vpc_id = aws_vpc.default.id

    tags = {
        Name = "Default Internet Gateway"
    }
}

resource "aws_subnet" "subnet" {
    vpc_id     = aws_vpc.default.id
    cidr_block = "10.0.0.0/24"
    availability_zone = "eu-west-3a"
}

# EC2 Creation example
module "EC2_Name" {
    source = "./modules/ec2"

    ec2_tag = "EC2 Name Production"
    ec2_name = "EC2-name-prod"
    service_name = "ec2-name-master"
    ec2_ports = [ 3000 ]
    domain_name = "ec2.name.com"
    vpc_id = aws_vpc.default.id
    subnet_id = aws_subnet.subnet.id
    internet_gateway_id = aws_internet_gateway.igw.id
}

output "EC2_IP" {
    value = module.EC2_Name.EC2_IP
}

# MongoDB Atlas Cluster
module "MongoDB_Cluster" {
    source = "./modules/cluster_mongodb"

    atlas_org_id = "<your-org-id>"
    atlas_project_name = "MongoDB-Project"
    environment = "production" // or "development"
    # Shared cluster: M0. Free
    # Dedicated cluster: M2, M5, M10... WARNING : Dedicated clusters are not free
    # For dedicated clusters, you can have backups by uncommenting in ./modules/cluster_mongodb/main.tf line 12 "backup_enabled = true"
    cluster_instance_size_name = "M0" // or "M2", "M5", "M10"...
    cluster_type = "REPLICASET" // or "SHARDED"
    cloud_provider = "AWS" // or "AZURE", "GCP"
    atlas_region = "EU_WEST_3"
    aws_region = "eu-west-3"
    mongodb_version = "6.0"
    mongodb_username = "admin"
    ip_address = module.EC2_Back-End.EC2_IP
    vpc_id = aws_vpc.default.id
    main_route_table_id = aws_vpc.default.main_route_table_id
    internet_gateway_id = aws_internet_gateway.igw.id
}

# #MongoDB Atlas Cluster Outputs
output "atlas_cluster_connection_string" { value = module.MongoDB_Cluster.atlas_cluster_connection_string }
output "ip_access_list" { value = module.MongoDB_Cluster.ip_access_list }
output "project_name" { value = module.MongoDB_Cluster.project_name }
output "mongodb_username" { value = module.MongoDB_Cluster.mongodb_username }
output "mongodb_password" {
    sensitive = true
    value = module.MongoDB_Cluster.mongodb_password
}
output "privatelink_connection_string" { value = module.MongoDB_Cluster.privatelink_connection_string }

################################################################################
# AWS S3 Bucket
################################################################################

# Classic S3 Bucket
module "S3_Bucket" {
    source = "./modules/s3"

    bucket_name = "s3-bucket-name"
}
