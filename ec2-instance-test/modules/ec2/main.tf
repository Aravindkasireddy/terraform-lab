# EC2 Instance Module
resource "aws_instance" "this" {
  ami                         = var.ami
  instance_type               = var.instance_type
  subnet_id                   = var.subnet_id
  vpc_security_group_ids      = var.security_group_ids
  associate_public_ip_address = var.associate_public_ip
  key_name                    = var.key_name

  # User data for initial configuration
  user_data = var.user_data

  # Root volume configuration
  root_block_device {
    volume_type           = var.root_volume_type
    volume_size           = var.root_volume_size
    delete_on_termination = true
    encrypted             = true
  }

  # Tags
  tags = merge(
    {
      Name        = var.instance_name
      Environment = var.environment
    },
    var.tags
  )
}
