# AWS Infrastructure with Terraform

This Terraform configuration provisions the necessary AWS infrastructure for UTSv2, including:

- **RDS PostgreSQL 16** - Managed database service
- **S3 Bucket** - Document storage with versioning and encryption
- **VPC** - Virtual Private Cloud with public/private subnets
- **Security Groups** - Network access control
- **IAM Roles** - For RDS enhanced monitoring

## Prerequisites

1. **AWS CLI** installed and configured
   ```bash
   aws configure
   ```

2. **Terraform** installed (version >= 1.0)
   ```bash
   # macOS
   brew install terraform
   
   # Or download from https://www.terraform.io/downloads
   ```

3. **AWS Credentials** with appropriate permissions

## Quick Start

1. **Navigate to the AWS terraform directory:**
   ```bash
   cd infra/terraform/aws
   ```

2. **Copy the example variables file:**
   ```bash
   cp terraform.tfvars.example terraform.tfvars
   ```

3. **Edit `terraform.tfvars` with your values:**
   ```bash
   # Edit the file with your preferred editor
   nano terraform.tfvars
   ```

4. **Initialize Terraform:**
   ```bash
   terraform init
   ```

5. **Review the planned changes:**
   ```bash
   terraform plan
   ```

6. **Apply the configuration:**
   ```bash
   terraform apply
   ```

7. **Note the outputs** - They contain your database connection information:
   ```bash
   terraform output database_url
   terraform output db_endpoint
   ```

## Configuration

### Variables

| Variable | Description | Default | Required |
|----------|-------------|---------|----------|
| `aws_region` | AWS region for resources | `us-east-1` | No |
| `environment` | Environment name | `dev` | No |
| `project_name` | Project name for resource naming | `utsv2` | No |
| `db_username` | PostgreSQL username | `utsv2admin` | No |
| `db_password` | PostgreSQL password | - | **Yes** |
| `db_name` | PostgreSQL database name | `utsv2` | No |

### Environment-Specific Settings

The configuration automatically adjusts based on the `environment` variable:

**Development (`dev`):**
- Smaller instance size (`db.t3.micro`)
- Publicly accessible database
- 1-day backup retention
- No deletion protection

**Production:**
- Larger instance size (`db.t3.small`)
- Private database (not publicly accessible)
- 7-day backup retention
- Deletion protection enabled
- Final snapshot on deletion

## Outputs

After applying, Terraform will output:

```bash
# Database connection information
terraform output db_endpoint
terraform output database_url

# Storage
terraform output s3_bucket_name

# Networking
terraform output vpc_id
```

## Database Connection

Use the outputs to configure your application:

```bash
# Get the connection string (sensitive output)
terraform output -raw database_url

# Example output:
# postgresql://utsv2admin:password@utsv2-dev-postgres-abc123.xyz.rds.amazonaws.com:5432/utsv2?sslmode=require
```

Add to your `.env` file:

```bash
DATABASE_URL=$(terraform output -raw database_url)
DB_HOST=$(terraform output -raw db_address)
DB_PORT=$(terraform output -raw db_port)
DB_USERNAME=utsv2admin
DB_PASSWORD=your_password
DB_NAME=$(terraform output -raw db_name)
```

## Security Notes

### Development Environment

⚠️ **Warning**: The development configuration includes:
- Publicly accessible RDS instance
- Security group allowing 0.0.0.0/0 on port 5432

**Remove these before production!**

### Production Environment

For production, the configuration automatically:
- ✅ Places RDS in private subnets
- ✅ Restricts access to VPC CIDR only
- ✅ Enables deletion protection
- ✅ Encrypts storage at rest
- ✅ Enables automated backups
- ✅ Enables CloudWatch monitoring

### Additional Security Recommendations

1. **Use AWS Secrets Manager** for database credentials
2. **Enable VPC Flow Logs** for network monitoring
3. **Implement AWS WAF** if exposing APIs publicly
4. **Set up CloudTrail** for audit logging
5. **Use AWS Systems Manager Parameter Store** for configuration

## Cost Estimation

Approximate monthly costs (US East 1):

**Development:**
- RDS PostgreSQL (db.t3.micro): ~$15/month
- S3 Storage (20GB): ~$0.50/month
- Data transfer: Variable
- **Total**: ~$15-20/month

**Production:**
- RDS PostgreSQL (db.t3.small): ~$30/month
- S3 Storage: Variable
- Enhanced Monitoring: ~$3/month
- Backups: Variable
- **Total**: ~$35-50+/month

Use [AWS Pricing Calculator](https://calculator.aws/) for detailed estimates.

## Maintenance

### Updating Infrastructure

```bash
# Make changes to *.tf files
# Plan the changes
terraform plan

# Apply the changes
terraform apply
```

### Destroying Infrastructure

⚠️ **Warning**: This will delete all resources, including databases!

```bash
terraform destroy
```

### State Management

For team environments, consider using remote state:

```hcl
# Add to main.tf
terraform {
  backend "s3" {
    bucket = "my-terraform-state-bucket"
    key    = "utsv2/terraform.tfstate"
    region = "us-east-1"
  }
}
```

## Troubleshooting

### Issue: Terraform can't find AWS credentials

**Solution**: Configure AWS CLI or set environment variables:
```bash
export AWS_ACCESS_KEY_ID="your-access-key"
export AWS_SECRET_ACCESS_KEY="your-secret-key"
export AWS_DEFAULT_REGION="us-east-1"
```

### Issue: RDS instance takes too long to create

**Solution**: This is normal. RDS instances typically take 5-10 minutes to provision.

### Issue: Can't connect to RDS from local machine

**Solution**: 
1. Check security group rules
2. Ensure `publicly_accessible = true` for dev environment
3. Verify your IP is allowed in the security group
4. Check VPC and subnet configuration

### Issue: Insufficient permissions

**Solution**: Ensure your AWS user/role has these permissions:
- EC2 (VPC, Subnets, Security Groups)
- RDS (Create, Modify, Delete instances)
- S3 (Create, Manage buckets)
- IAM (Create roles, policies)

## Migration from SQLite

If migrating from SQLite:

1. **Deploy infrastructure with Terraform**
2. **Export SQLite data:**
   ```bash
   ruby script/utilities/export_sqlite_data.rb
   ```

3. **Import to PostgreSQL:**
   ```bash
   DATABASE_URL=$(terraform output -raw database_url) \
   ruby script/utilities/import_to_postgres.rb
   ```

## Support

For issues or questions:
- Check the [main project README](../../../README.md)
- Review [AWS RDS documentation](https://docs.aws.amazon.com/rds/)
- Review [Terraform AWS Provider docs](https://registry.terraform.io/providers/hashicorp/aws/latest/docs)

