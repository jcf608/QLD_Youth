# GCP Infrastructure with Terraform

This Terraform configuration provisions the necessary GCP infrastructure for UTSv2, including:

- **Cloud SQL PostgreSQL 16** - Managed database service
- **Cloud Storage** - Document storage with versioning
- **VPC Network** - Private networking for Cloud SQL
- **Service Account** - Application identity and permissions
- **IAM Bindings** - Access control

## Prerequisites

1. **GCP Account** with billing enabled

2. **gcloud CLI** installed and configured
   ```bash
   gcloud init
   gcloud auth application-default login
   ```

3. **Terraform** installed (version >= 1.0)
   ```bash
   # macOS
   brew install terraform
   
   # Or download from https://www.terraform.io/downloads
   ```

4. **GCP Project** created
   ```bash
   gcloud projects create my-project-id
   gcloud config set project my-project-id
   ```

## Quick Start

1. **Navigate to the GCP terraform directory:**
   ```bash
   cd infra/terraform/gcp
   ```

2. **Copy the example variables file:**
   ```bash
   cp terraform.tfvars.example terraform.tfvars
   ```

3. **Edit `terraform.tfvars` with your values:**
   ```bash
   nano terraform.tfvars
   ```
   
   **Important**: Set your `gcp_project_id`!

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
   
   This will take 5-10 minutes as Cloud SQL instances take time to provision.

7. **Note the outputs:**
   ```bash
   terraform output database_url
   terraform output db_connection_name
   ```

## Configuration

### Variables

| Variable | Description | Default | Required |
|----------|-------------|---------|----------|
| `gcp_project_id` | GCP Project ID | - | **Yes** |
| `gcp_region` | GCP region for resources | `us-central1` | No |
| `gcp_zone` | GCP zone for resources | `us-central1-a` | No |
| `environment` | Environment name | `dev` | No |
| `project_name` | Project name for resource naming | `utsv2` | No |
| `db_username` | PostgreSQL username | `utsv2admin` | No |
| `db_password` | PostgreSQL password | - | **Yes** |
| `db_name` | PostgreSQL database name | `utsv2` | No |

### Environment-Specific Settings

**Development (`dev`):**
- Micro instance size (`db-f1-micro`)
- Single zone availability
- Public IP access enabled
- 1-day backup retention
- No deletion protection

**Production:**
- Custom instance size (`db-custom-2-4096`)
- Regional availability (high availability)
- Private VPC with optional public IP
- 7-day backup retention
- Point-in-time recovery enabled
- Deletion protection enabled

## Database Connection

### Option 1: Direct Connection (Development)

For development, you can connect directly using the public IP:

```bash
# Get the connection string
terraform output -raw database_url

# Example output:
# postgresql://utsv2admin:password@34.123.45.67:5432/utsv2?sslmode=require
```

### Option 2: Cloud SQL Proxy (Recommended)

For production and secure connections, use Cloud SQL Proxy:

```bash
# Get the connection name
terraform output db_connection_name

# Example: my-project:us-central1:utsv2-dev-postgres-abc123

# Download and run Cloud SQL Proxy
curl -o cloud-sql-proxy https://storage.googleapis.com/cloud-sql-connectors/cloud-sql-proxy/v2.8.0/cloud-sql-proxy.darwin.amd64
chmod +x cloud-sql-proxy

# Start the proxy
./cloud-sql-proxy --port 5432 $(terraform output -raw db_connection_name)

# Now connect to localhost:5432
DATABASE_URL=postgresql://utsv2admin:password@localhost:5432/utsv2
```

### Environment Configuration

Add to your `.env` file:

```bash
# Using public IP (development)
DATABASE_URL=$(terraform output -raw database_url)

# Or using Cloud SQL Proxy (recommended)
DATABASE_URL=postgresql://utsv2admin:your_password@localhost:5432/utsv2

# Individual components
DB_HOST=$(terraform output -raw db_public_ip)  # or localhost if using proxy
DB_PORT=5432
DB_USERNAME=utsv2admin
DB_PASSWORD=your_password
DB_NAME=$(terraform output -raw db_name)

# Cloud Storage
GCS_BUCKET=$(terraform output -raw storage_bucket_name)
GOOGLE_CLOUD_PROJECT=your-project-id
```

## Security Notes

### Development Environment

⚠️ **Warning**: The development configuration includes:
- Public IP enabled on Cloud SQL
- Authorized network allowing 0.0.0.0/0

**Remove these before production!**

### Production Environment

For production, the configuration automatically:
- ✅ Uses regional availability (high availability)
- ✅ Enables automated backups
- ✅ Enables point-in-time recovery
- ✅ Uses private VPC connection
- ✅ Enables deletion protection
- ✅ Encrypts data at rest

### Additional Security Recommendations

1. **Use Secret Manager** for database credentials:
   ```bash
   gcloud secrets create db-password --data-file=-
   ```

2. **Enable Cloud Armor** for DDoS protection

3. **Set up Cloud Audit Logs** for compliance

4. **Use Workload Identity** for GKE deployments

5. **Enable VPC Flow Logs** for network monitoring

## Cost Estimation

Approximate monthly costs (us-central1):

**Development:**
- Cloud SQL (db-f1-micro): ~$10/month
- Storage (20GB): ~$0.40/month
- Network egress: Variable
- **Total**: ~$10-15/month

**Production:**
- Cloud SQL (db-custom-2-4096): ~$115/month
- Storage: Variable
- Backups: ~$0.08/GB/month
- Network egress: Variable
- **Total**: ~$120-150+/month

Use [GCP Pricing Calculator](https://cloud.google.com/products/calculator) for detailed estimates.

## Cloud SQL Proxy Setup

### Using Docker

```bash
docker run -d \
  -p 5432:5432 \
  gcr.io/cloud-sql-connectors/cloud-sql-proxy:latest \
  --port 5432 \
  $(terraform output -raw db_connection_name)
```

### Using Kubernetes

```yaml
# Add as a sidecar container
- name: cloud-sql-proxy
  image: gcr.io/cloud-sql-connectors/cloud-sql-proxy:latest
  args:
    - "--port=5432"
    - "$(DB_CONNECTION_NAME)"
  env:
    - name: DB_CONNECTION_NAME
      value: "PROJECT:REGION:INSTANCE"
```

## Maintenance

### Updating Infrastructure

```bash
# Make changes to *.tf files
terraform plan
terraform apply
```

### Backups and Recovery

```bash
# List backups
gcloud sql backups list --instance=$(terraform output -raw db_instance_name)

# Create on-demand backup
gcloud sql backups create --instance=$(terraform output -raw db_instance_name)

# Restore from backup
gcloud sql backups restore BACKUP_ID \
  --backup-instance=$(terraform output -raw db_instance_name) \
  --backup-id=BACKUP_ID
```

### Destroying Infrastructure

⚠️ **Warning**: This will delete all resources!

```bash
terraform destroy
```

### State Management

For team environments, use Cloud Storage for remote state:

```hcl
# Add to main.tf
terraform {
  backend "gcs" {
    bucket = "my-terraform-state-bucket"
    prefix = "utsv2/state"
  }
}
```

Create the bucket:
```bash
gsutil mb gs://my-terraform-state-bucket
gsutil versioning set on gs://my-terraform-state-bucket
```

## Troubleshooting

### Issue: APIs not enabled

**Solution**: Enable required APIs:
```bash
gcloud services enable compute.googleapis.com
gcloud services enable sqladmin.googleapis.com
gcloud services enable storage.googleapis.com
gcloud services enable servicenetworking.googleapis.com
```

### Issue: Insufficient permissions

**Solution**: Ensure your account has these roles:
- Compute Admin
- Cloud SQL Admin
- Storage Admin
- Service Account Admin

```bash
gcloud projects add-iam-policy-binding PROJECT_ID \
  --member="user:your-email@example.com" \
  --role="roles/editor"
```

### Issue: Can't connect to Cloud SQL

**Solution**:
1. Check if public IP is enabled
2. Verify authorized networks
3. Use Cloud SQL Proxy for secure connection
4. Check firewall rules

### Issue: Quota exceeded

**Solution**: Request quota increase:
```bash
gcloud compute project-info describe --project=PROJECT_ID
```
Visit: https://console.cloud.google.com/iam-admin/quotas

## Migration from SQLite

If migrating from SQLite:

1. **Deploy infrastructure with Terraform**

2. **Start Cloud SQL Proxy:**
   ```bash
   ./cloud-sql-proxy --port 5432 $(terraform output -raw db_connection_name)
   ```

3. **Export SQLite data:**
   ```bash
   ruby script/utilities/export_sqlite_data.rb
   ```

4. **Import to PostgreSQL:**
   ```bash
   DATABASE_URL=postgresql://utsv2admin:password@localhost:5432/utsv2 \
   ruby script/utilities/import_to_postgres.rb
   ```

## Monitoring

### Cloud SQL Insights

Query insights are enabled by default. View in Console:
https://console.cloud.google.com/sql/instances/INSTANCE/insights

### Metrics

Key metrics to monitor:
- `cloudsql.googleapis.com/database/cpu/utilization`
- `cloudsql.googleapis.com/database/memory/utilization`
- `cloudsql.googleapis.com/database/disk/utilization`
- `cloudsql.googleapis.com/database/network/connections`

### Alerts

Set up alerts:
```bash
# Example: CPU alert
gcloud alpha monitoring policies create \
  --notification-channels=CHANNEL_ID \
  --display-name="High CPU" \
  --condition-display-name="CPU over 80%" \
  --condition-threshold-value=0.8 \
  --condition-threshold-duration=300s
```

## Support

For issues or questions:
- Check the [main project README](../../../README.md)
- Review [Cloud SQL documentation](https://cloud.google.com/sql/docs)
- Review [Terraform GCP Provider docs](https://registry.terraform.io/providers/hashicorp/google/latest/docs)
- Visit [GCP Console](https://console.cloud.google.com/)

