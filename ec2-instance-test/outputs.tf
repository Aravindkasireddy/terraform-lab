output "instance_id" {
  description = "The ID of the EC2 instance"
  value       = module.web_server.instance_id
}

output "public_ip" {
  description = "Public IP address of the instance"
  value       = module.web_server.public_ip
}

output "private_ip" {
  description = "Private IP address of the instance"
  value       = module.web_server.private_ip
}

output "instance_state" {
  description = "The state of the instance"
  value       = module.web_server.instance_state
}

output "availability_zone" {
  description = "The availability zone of the instance"
  value       = module.web_server.availability_zone
}
