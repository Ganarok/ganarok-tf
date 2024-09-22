# Create an Atlas Advanced Cluster 
resource "mongodbatlas_advanced_cluster" "atlas-cluster" {
    project_id = mongodbatlas_project.atlas-project.id
    name = "${var.atlas_project_name}-${var.environment}-cluster"
    cluster_type = var.cluster_type
    backup_enabled = var.cluster_instance_size_name == "M0" ? false : true # Uncomment to enable backup, only available if not M0
    # cloud_backup = var.cluster_instance_size_name == "M0" ? false : true # Uncomment to enable cloud backup, only available if not M0. That's a cost !

    replication_specs { // Required for REPLICASET. Not required for SHARDED. Cost is higher for REPLICASET
        region_configs {
            electable_specs {
                instance_size = var.cluster_instance_size_name
                node_count    = 3
            }
            analytics_specs {
                instance_size = var.cluster_instance_size_name
                node_count    = 1
            }
            priority      = 7
            provider_name = "TENANT"
            backing_provider_name = var.cloud_provider
            region_name   = var.atlas_region
        }
    }
}

# Create a project
resource "mongodbatlas_project" "atlas-project" {
    org_id = var.atlas_org_id
    name = var.atlas_project_name
}

# Create a cloud backup schedule. Uncomment if your cluster is not M0
# resource "mongodbatlas_cloud_backup_schedule" "test" {
#     project_id   = mongodbatlas_cluster.atlas-cluster.project_id
#     cluster_name = mongodbatlas_cluster.atlas-cluster.name

#     reference_hour_of_day    = 3
#     reference_minute_of_hour = 45
#     restore_window_days      = 4
# }

# Route Table
resource "aws_route" "primary-internet_access" {
    route_table_id         = var.main_route_table_id
    destination_cidr_block = "0.0.0.0/0"
    gateway_id             = var.internet_gateway_id
}


resource "aws_security_group" "default" {
    name_prefix = "default-"
    description = "Default security group for all instances in ${var.vpc_id}"
    vpc_id      = var.vpc_id

    ingress {
        from_port = 0
        to_port   = 0
        protocol  = "tcp"
        cidr_blocks = [
        "0.0.0.0/0",
        ]
    }
    egress {
        from_port   = 0
        to_port     = 0
        protocol    = "-1"
        cidr_blocks = ["0.0.0.0/0"]
    }
}

# Create a Database Password
resource "random_password" "db-user-password" {
    length = 16
    special = true
    override_special = "_"
}

# Create a Database User
resource "mongodbatlas_database_user" "db-user" {
    username = var.mongodb_username
    password = random_password.db-user-password.result
    project_id = mongodbatlas_project.atlas-project.id
    auth_database_name = "admin"

    roles {
        role_name     = "readWrite"
        database_name = var.atlas_project_name
    }
}

# Create Database IP Access List 
resource "mongodbatlas_project_ip_access_list" "ip" {
    project_id = mongodbatlas_project.atlas-project.id
    ip_address = var.ip_address
    comment    = "IP Address for ${var.atlas_project_name}"
}

resource "mongodbatlas_privatelink_endpoint" "atlaspl" {
    project_id    = mongodbatlas_project.atlas-project.id
    provider_name = "AWS"
    region        = var.atlas_region
}

# Create Primary VPC
# resource "aws_vpc" "primary" {
#     cidr_block           = "10.0.0.0/16"
#     enable_dns_hostnames = true
#     enable_dns_support   = true
# }

# Subnet-A
resource "aws_subnet" "primary-az1" {
    vpc_id                  = var.vpc_id
    cidr_block              = "10.0.1.0/24"
    map_public_ip_on_launch = true
    availability_zone       = "${var.aws_region}a"
}

# Subnet-B
resource "aws_subnet" "primary-az2" {
    vpc_id                  = var.vpc_id
    cidr_block              = "10.0.2.0/24"
    map_public_ip_on_launch = false
    availability_zone       = "${var.aws_region}b"
}

resource "aws_vpc_endpoint" "ptfe_service" {
    vpc_id             = var.vpc_id
    service_name       = mongodbatlas_privatelink_endpoint.atlaspl.endpoint_service_name
    vpc_endpoint_type  = "Interface"
    subnet_ids         = [aws_subnet.primary-az1.id, aws_subnet.primary-az2.id]
    security_group_ids = [aws_security_group.default.id]
}

resource "mongodbatlas_privatelink_endpoint_service" "atlaseplink" {
    project_id          = mongodbatlas_privatelink_endpoint.atlaspl.project_id
    private_link_id     = mongodbatlas_privatelink_endpoint.atlaspl.id
    endpoint_service_id = aws_vpc_endpoint.ptfe_service.id
    provider_name       = "AWS"
}

data "mongodbatlas_advanced_cluster" "atlas-cluster" {
    project_id = mongodbatlas_project.atlas-project.id
    name       = mongodbatlas_advanced_cluster.atlas-cluster.name
    depends_on = [mongodbatlas_privatelink_endpoint_service.atlaseplink]
}

# Outputs to Display
output "atlas_cluster_connection_string" { value = mongodbatlas_advanced_cluster.atlas-cluster.connection_strings.0.standard_srv }
output "ip_access_list"    { value = mongodbatlas_project_ip_access_list.ip.ip_address }
output "project_name"      { value = mongodbatlas_project.atlas-project.name }
output "mongodb_username"          { value = mongodbatlas_database_user.db-user.username } 
output "mongodb_password"     { 
    sensitive = true
    value = mongodbatlas_database_user.db-user.password 
}

output "privatelink_connection_string" {
    value = lookup(mongodbatlas_advanced_cluster.atlas-cluster.connection_strings[0].aws_private_link_srv, "connection_string", null)
}
