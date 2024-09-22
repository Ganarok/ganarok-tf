# Atlas Organization ID 
variable "atlas_org_id" {
    type        = string
    description = "Atlas Organization ID"
}
# Atlas Project Name
variable "atlas_project_name" {
    type        = string
    description = "Atlas Project Name"
}

# Atlas Project Environment
variable "environment" {
    type        = string
    description = "The environment to be built"
}

# Cluster Instance Size Name 
variable "cluster_instance_size_name" {
    type        = string
    description = "Cluster instance size name"
}

# Atlas Region
variable "atlas_region" {
    type        = string
    description = "Atlas Region"
}

# MongoDB Version
variable "mongodb_version" {
    type        = string
    description = "MongoDB Version"
}

# Cloud Provider
variable "cloud_provider" {
    type        = string
    description = "Cloud Provider"
}

# IP Address
variable "ip_address" {
    type        = string
    description = "IP Address"
}

# AWS Region
variable "aws_region" {
    type        = string
    description = "AWS Region"
}

# VPC ID
variable "vpc_id" {
    type        = string
    description = "VPC ID"
}

variable "cluster_type" {
    type        = string
    description = "Cluster Type"
}

variable "main_route_table_id" {
    type        = string
    description = "Main Route Table ID"
}

variable "mongodb_username" {
    type        = string
    default     = "admin"
    description = "MongoDB Username"
}

variable "internet_gateway_id" {
    type        = string
    description = "Internet Gateway ID"
}