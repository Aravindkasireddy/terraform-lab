# EC2 Instance Test Module

This directory contains a Terraform configuration that uses a modular structure to create an EC2 instance.

## Directory Structure

```
ec2-instance-test/
├── main.tf                    # Root configuration that calls the module
├── variables.tf               # Root input variables
├── outputs.tf                 # Root outputs
├── provider.tf                # AWS provider configuration
├── terraform.tfvars.example   # Example variable values
└── modules/
    └── ec2/
        ├── main.tf           # EC2 module resources
        ├── variables.tf      # Module input variables
        └── outputs.tf        # Module outputs
```

## How Modules Work

### Module Structure

**Root Level** (`ec2-instance-test/`):
- Calls the module
- Passes variables to the module
- Exposes module outputs

**Module Level** (`modules/ec2/`):
- Contains reusable EC2 instance configuration
- Can be called multiple times with different parameters
- Encapsulates the actual resource creation

### Data Flow

```
User Input → Root Variables → Module Variables → Resources → Module Outputs → Root Outputs
```

## Usage

### 1. Setup

```bash
cd ec2-instance-test

# Copy the example tfvars file
cp terraform.tfvars.example terraform.tfvars

# Edit terraform.tfvars with your values
notepad terraform.tfvars
```

### 2. Update `terraform.tfvars`

```hcl
ami                = "ami-0c55b159cbfafe1f0"  # Your AMI ID
instance_type      = "t2.micro"
subnet_id          = "subnet-xxxxx"           # From your VPC
security_group_ids = ["sg-xxxxx"]             # Your security group
instance_name      = "my-test-server"
environment        = "dev"
```

### 3. Deploy

```bash
# Initialize Terraform (downloads providers and modules)
terraform init

# See what will be created
terraform plan

# Create the infrastructure
terraform apply
```

### 4. Access Outputs

```bash
# View all outputs
terraform output

# View specific output
terraform output instance_id
terraform output public_ip
```

## Module Benefits

✅ **Reusability**: Use the same module multiple times
✅ **Maintainability**: Update module once, affects all instances
✅ **Organization**: Clean separation of concerns
✅ **Testing**: Test module independently
✅ **Sharing**: Share modules across projects or teams

## Example: Using the Module Multiple Times

You can call the module multiple times to create multiple instances:

```hcl
# main.tf
module "web_server" {
  source = "./modules/ec2"
  
  ami                = var.ami
  instance_type      = "t2.micro"
  subnet_id          = var.public_subnet_id
  security_group_ids = [var.web_sg_id]
  instance_name      = "web-server"
}

module "db_server" {
  source = "./modules/ec2"
  
  ami                = var.ami
  instance_type      = "t3.medium"
  subnet_id          = var.private_subnet_id
  security_group_ids = [var.db_sg_id]
  instance_name      = "database-server"
  associate_public_ip = false
}
```

## Clean Up

```bash
# Destroy all resources
terraform destroy
```

## Next Steps

- Customize the module in `modules/ec2/` for your needs
- Add more modules (e.g., VPC, RDS, S3)
- Use remote state for team collaboration
- Implement different environments (dev, staging, prod)
