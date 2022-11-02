// AWS Credentials
variable "aws_access_key" {}
variable "aws_secret_key" {}

// AWS Region where we're deploying the gateway.
variable "region" {
  default = "us-east-1"
}

// Primary CIDR for the gateway.
// Connecting to resources in other VPCs will require the VPC Peering connections.
variable "vpc_cidr" {
  default = "10.0.0.0/16"
}

// Demo subnets for our resources.
variable "vpc_public_subnets" {
  default = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
}

// Availability zones withing region
variable "vpc_azs" {
  default = ["us-east-1a", "us-east-1b", "us-east-1c"]
}

// Gateway instance SSH public key
variable "gateway_ssh_public_key" {
  default = "../ansible/keys/ssh.pub"
}

// Gateway instance type.
// t3.micro will be enough for most users, depending on connected devices.
variable "gateway_instance_type" {
  default = "t3.micro"
}

// Gateway instance disk volume size.
// We're not storing any data so any smaller volume size would work fine.
variable "gateway_instance_disk_size" {
  default = "12"
}

// Wireguard primary gateway CIDR.
variable "gateway_network" {
  default = "10.10.0.0/24"
}
