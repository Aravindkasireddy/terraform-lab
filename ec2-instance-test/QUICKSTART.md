# Quick Start Guide - EC2 Instance Creation

## Prerequisites

Before running this code, you need:

1. ✅ AWS Account with credentials configured
2. ✅ VPC with at least one subnet
3. ✅ Security group allowing HTTP (port 80) and SSH (port 22)
4. ✅ (Optional) EC2 Key Pair for SSH access

## Step 1: Configure AWS Credentials

Make sure your AWS credentials are set up:

```bash
# Option 1: AWS CLI configured
aws configure

# Option 2: Environment variables
set AWS_ACCESS_KEY_ID=your_access_key
set AWS_SECRET_ACCESS_KEY=your_secret_key
set AWS_DEFAULT_REGION=us-east-1
```

## Step 2: Get Required IDs

You need to update `terraform.tfvars` with values from your VPC:

### Get Subnet ID
```bash
aws ec2 describe-subnets --query 'Subnets[*].[SubnetId,VpcId,CidrBlock,AvailabilityZone]' --output table
```

### Get Security Group ID
```bash
aws ec2 describe-security-groups --query 'SecurityGroups[*].[GroupId,GroupName,VpcId]' --output table
```

### Get Latest Amazon Linux 2 AMI (Optional - for current AMI)
```bash
aws ec2 describe-images --owners amazon --filters "Name=name,Values=amzn2-ami-hvm-*-x86_64-gp2" --query 'Images | sort_by(@, &CreationDate) | [-1].ImageId' --output text
```

## Step 3: Update terraform.tfvars

Edit `terraform.tfvars` and replace these values:

```hcl
subnet_id          = "subnet-xxxxx"  # From Step 2
security_group_ids = ["sg-xxxxx"]    # From Step 2
ami                = "ami-xxxxx"     # (Optional) From Step 2
key_name           = "my-key-pair"   # (Optional) Your SSH key name
```

## Step 4: Initialize Terraform

```bash
cd ec2-instance-test
terraform init
```

**What this does:**
- Downloads AWS provider
- Initializes the backend
- Prepares the module

## Step 5: Plan the Deployment

```bash
terraform plan
```

**Expected output:**
```
Plan: 1 to add, 0 to change, 0 to destroy.
```

**Review the plan to see:**
- Instance type: t2.micro
- Storage: 20GB gp3 volume
- Network: Your subnet and security group
- User data: Apache web server installation

## Step 6: Apply (Create the Instance)

```bash
terraform apply
```

Type `yes` when prompted.

**This will create:**
- 1 EC2 instance with Apache web server
- Encrypted root volume
- Public IP address (if configured)
- Tags for organization

## Step 7: Get Outputs

```bash
# View all outputs
terraform output

# Get specific values
terraform output instance_id
terraform output public_ip
terraform output private_ip
```

## Step 8: Verify the Web Server

Once the instance is created, test the web server:

```bash
# Get the public IP
$PUBLIC_IP = terraform output -raw public_ip

# Open in browser (or use curl)
curl http://$PUBLIC_IP
```

You should see: "Hello from Terraform EC2 Instance!"

## Step 9: SSH into Instance (Optional)

If you configured a key pair:

```bash
$PUBLIC_IP = terraform output -raw public_ip
ssh -i path/to/your-key.pem ec2-user@$PUBLIC_IP
```

## Step 10: Clean Up (Destroy Resources)

When you're done testing:

```bash
terraform destroy
```

Type `yes` to confirm deletion.

---

## Troubleshooting

### Issue: "InvalidSubnet.NotFound"
**Solution:** Update `subnet_id` in terraform.tfvars with a valid subnet from your VPC

### Issue: "InvalidGroup.NotFound"  
**Solution:** Update `security_group_ids` in terraform.tfvars with a valid security group

### Issue: "InvalidAMIID.Malformed"
**Solution:** Use the AWS CLI command above to get a current AMI ID for your region

### Issue: "UnauthorizedOperation"
**Solution:** Check your AWS credentials and IAM permissions

### Issue: Can't access web server
**Solution:** Ensure your security group allows inbound HTTP (port 80) from 0.0.0.0/0

---

## What Gets Created

| Resource | Details |
|----------|---------|
| **EC2 Instance** | t2.micro (Free Tier eligible) |
| **Root Volume** | 20GB gp3, encrypted |
| **Software** | Amazon Linux 2 + Apache |
| **Public IP** | Yes (can access via HTTP) |
| **Tags** | Name, Environment, Project, etc. |

---

## Cost Estimate

- **t2.micro**: Free tier eligible (750 hours/month free for first year)
- **EBS gp3**: ~$0.08/GB/month = ~$1.60/month for 20GB
- **Data transfer**: Minimal for testing

**Estimated cost:** $0-2/month depending on free tier status

---

## Next Steps

1. ✅ Modify user_data in terraform.tfvars to customize setup
2. ✅ Change instance_type for more power
3. ✅ Add more instances by calling the module multiple times
4. ✅ Create additional modules (VPC, RDS, etc.)
5. ✅ Set up remote state with S3 backend
