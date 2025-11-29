# Root Configuration - Using EC2 Module

# Call the EC2 module
module "web_server" {
  source = "./modules/ec2"

  # Required variables
  ami                = var.ami
  instance_type      = var.instance_type
  subnet_id          = var.subnet_id
  security_group_ids = var.security_group_ids
  instance_name      = var.instance_name

  # Optional variables
  environment        = var.environment
  associate_public_ip = var.associate_public_ip
  key_name           = var.key_name
  root_volume_type   = var.root_volume_type
  root_volume_size   = var.root_volume_size

  # User data for web server setup
  user_data = var.user_data

  # Additional tags
  tags = var.tags
}
