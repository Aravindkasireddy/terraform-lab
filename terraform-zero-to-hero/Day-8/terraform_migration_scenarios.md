# Terraform Migration Scenarios

This guide covers common scenarios where you need to migrate existing infrastructure to Terraform management or migrate between different Terraform configurations.

---

## 🎯 Migration Scenario 1: Import Existing AWS Resources

**Problem**: You have AWS resources created manually via Console/CLI, and you want Terraform to manage them.

### Example: Import an Existing EC2 Instance

**Step 1: Create the Terraform Configuration**

```hcl
# main.tf
resource "aws_instance" "imported_server" {
  ami           = "ami-053b0d53c279acc90"
  instance_type = "t2.micro"
  
  tags = {
    Name = "manually-created-server"
  }
}
```

**Step 2: Import the Existing Resource**

```bash
# Find your instance ID from AWS Console (e.g., i-0123456789abcdef0)
terraform import aws_instance.imported_server i-0123456789abcdef0
```

**Step 3: Verify the Import**

```bash
terraform show
# This will show the imported resource in state

terraform plan
# Should show minimal or no changes if your .tf matches the real resource
```

**Step 4: Adjust Configuration to Match Reality**

```bash
# If terraform plan shows changes, update your .tf file to match
# the actual resource configuration shown in terraform show
```

---

## 🎯 Migration Scenario 2: State Migration Between Backends

**Problem**: Moving from local state file to remote backend (S3).

### Before: Local State

```hcl
# No backend configuration - state stored locally
terraform {
  required_version = ">= 1.0"
}
```

### After: Remote S3 Backend

**Step 1: Create S3 Bucket for State**

```bash
aws s3 mb s3://my-terraform-state-bucket
aws s3api put-bucket-versioning \
  --bucket my-terraform-state-bucket \
  --versioning-configuration Status=Enabled
```

**Step 2: Add Backend Configuration**

```hcl
terraform {
  backend "s3" {
    bucket         = "my-terraform-state-bucket"
    key            = "prod/terraform.tfstate"
    region         = "us-east-1"
    encrypt        = true
    dynamodb_table = "terraform-state-lock"  # For state locking
  }
}
```

**Step 3: Migrate State**

```bash
terraform init -migrate-state
# Terraform will ask: "Do you want to copy existing state to the new backend?"
# Answer: yes
```

**Step 4: Verify Migration**

```bash
# Check that state is now in S3
aws s3 ls s3://my-terraform-state-bucket/prod/

# Local terraform.tfstate should now be a backup
ls -la terraform.tfstate.backup
```

---

## 🎯 Migration Scenario 3: Resource Rename/Refactoring

**Problem**: You renamed a resource in code, but Terraform thinks it's a delete + create.

### Before

```hcl
resource "aws_instance" "old_name" {
  ami           = "ami-053b0d53c279acc90"
  instance_type = "t2.micro"
}
```

### After (Naive Approach - WRONG!)

```hcl
resource "aws_instance" "new_name" {  # ❌ Terraform will destroy old and create new!
  ami           = "ami-053b0d53c279acc90"
  instance_type = "t2.micro"
}
```

### Correct Approach: Use `terraform state mv`

```bash
# Move the resource in state to match the new name
terraform state mv aws_instance.old_name aws_instance.new_name

# Now update your .tf file
# main.tf
resource "aws_instance" "new_name" {  # ✅ No destruction!
  ami           = "ami-053b0d53c279acc90"
  instance_type = "t2.micro"
}

# Verify no changes needed
terraform plan
# Output: No changes. Your infrastructure matches the configuration.
```

---

## 🎯 Migration Scenario 4: Workspace to Workspace Migration

**Problem**: Move resources from one workspace to another.

### Example: Move from dev to prod workspace

```bash
# Select dev workspace
terraform workspace select dev

# Pull state to a file
terraform state pull > dev-state.json

# Select prod workspace
terraform workspace select prod

# Push state from dev to prod
terraform state push dev-state.json

# Clean up
rm dev-state.json
```

**Warning**: This is dangerous! Better approach is to recreate resources in the new workspace.

---

## 🎯 Migration Scenario 5: Module Migration

**Problem**: Converting standalone resources to use modules.

### Before: Standalone Resources

```hcl
# main.tf
resource "aws_instance" "web1" {
  ami           = "ami-053b0d53c279acc90"
  instance_type = "t2.micro"
  tags = { Name = "web-1" }
}

resource "aws_instance" "web2" {
  ami           = "ami-053b0d53c279acc90"
  instance_type = "t2.micro"
  tags = { Name = "web-2" }
}
```

### After: Using Module

**Step 1: Create Module**

```hcl
# modules/ec2/main.tf
resource "aws_instance" "this" {
  ami           = var.ami
  instance_type = var.instance_type
  tags          = var.tags
}
```

**Step 2: Use Module in Main Config**

```hcl
# main.tf
module "web1" {
  source        = "./modules/ec2"
  ami           = "ami-053b0d53c279acc90"
  instance_type = "t2.micro"
  tags          = { Name = "web-1" }
}

module "web2" {
  source        = "./modules/ec2"
  ami           = "ami-053b0d53c279acc90"
  instance_type = "t2.micro"
  tags          = { Name = "web-2" }
}
```

**Step 3: Migrate State**

```bash
# Move resources into module
terraform state mv aws_instance.web1 module.web1.aws_instance.this
terraform state mv aws_instance.web2 module.web2.aws_instance.this

# Verify
terraform plan
# Should show no changes
```

---

## 🎯 Migration Scenario 6: Terraform Version Upgrade

**Problem**: Upgrading from Terraform 0.12 to 1.x

### Migration Steps

**Step 1: Backup Everything**

```bash
# Backup state file
cp terraform.tfstate terraform.tfstate.backup

# Backup configuration
tar -czf terraform-configs-backup.tar.gz *.tf
```

**Step 2: Upgrade Terraform Binary**

```bash
# Install new version
# On Windows: Download from terraform.io
# On Linux:
wget https://releases.hashicorp.com/terraform/1.13.1/terraform_1.13.1_linux_amd64.zip
unzip terraform_1.13.1_linux_amd64.zip
sudo mv terraform /usr/local/bin/
```

**Step 3: Upgrade Configuration Syntax**

```bash
# Terraform 0.13+ provides upgrade command
terraform 0.13upgrade .

# For Terraform 1.x, check for deprecated syntax
terraform plan
```

**Step 4: Update State File Format**

```bash
terraform init -upgrade
terraform apply -refresh-only
```

---

## 🎯 Migration Scenario 7: Drift Detection & Remediation

**Problem**: Someone made manual changes to infrastructure in AWS Console.

### Detect Drift

```bash
# Refresh state and show differences
terraform plan -refresh-only

# Or use newer command
terraform plan
```

### Example Output

```
Terraform will perform the following actions:

  # aws_instance.web will be updated in-place
  ~ resource "aws_instance" "web" {
        id            = "i-0123456789abcdef0"
      ~ instance_type = "t2.small" -> "t2.micro"  # Someone changed this manually!
      ~ tags          = {
          ~ "Environment" = "prod" -> "production"  # Tag was changed
        }
    }
```

### Remediation Options

**Option 1: Accept the Manual Changes**

```bash
# Update your .tf file to match reality
# main.tf
resource "aws_instance" "web" {
  instance_type = "t2.small"  # Accept the manual change
  tags = {
    Environment = "production"
  }
}
```

**Option 2: Revert to Terraform Configuration**

```bash
# Apply will revert the manual changes
terraform apply
# This will change instance_type back to t2.micro
```

**Option 3: Import Current State**

```bash
# Update state to match reality without changing infrastructure
terraform apply -refresh-only
```

---

## 🎯 Migration Scenario 8: Multi-Account AWS Migration

**Problem**: Moving resources between AWS accounts.

### Approach

You **cannot** move actual AWS resources between accounts. Instead:

**Step 1: Create New Resources in Target Account**

```hcl
# Configure provider for new account
provider "aws" {
  alias   = "target"
  region  = "us-east-1"
  profile = "target-account-profile"
}

# Create resources in new account
resource "aws_instance" "migrated" {
  provider      = aws.target
  ami           = "ami-053b0d53c279acc90"
  instance_type = "t2.micro"
}
```

**Step 2: Migrate Data**

- Take snapshots of EBS volumes
- Copy AMIs to new account
- Export/import databases

**Step 3: Destroy Old Resources**

```bash
terraform destroy -target=aws_instance.old
```

---

## 🛠️ Essential Commands for Migration

| Command | Use Case |
|---------|----------|
| `terraform import` | Import existing resources |
| `terraform state mv` | Rename resources |
| `terraform state rm` | Remove from state without destroying |
| `terraform state pull` | Export state to file |
| `terraform state push` | Import state from file |
| `terraform state list` | List all resources in state |
| `terraform state show` | Show resource details |
| `terraform plan -refresh-only` | Detect drift |
| `terraform init -migrate-state` | Migrate backend |

---

## ⚠️ Migration Best Practices

1. **Always backup state before migration**
   ```bash
   cp terraform.tfstate terraform.tfstate.backup.$(date +%Y%m%d-%H%M%S)
   ```

2. **Test migrations in a non-production environment first**

3. **Use version control** - commit before and after migrations

4. **Document the migration** - explain why and how

5. **Verify with `terraform plan`** - should show no changes after migration

6. **Use `-target` flag** for selective operations
   ```bash
   terraform apply -target=aws_instance.specific_server
   ```

7. **Enable state locking** to prevent concurrent modifications

8. **Use remote state** for team collaboration

---

## 🎓 Summary

Terraform migration involves:
- **Importing** existing resources
- **Moving** state between backends
- **Refactoring** resource names
- **Detecting and fixing** drift
- **Upgrading** Terraform versions
- **Migrating** between workspaces/accounts

The key is to **always use state manipulation commands** rather than manual state file editing!
