# PostgreSQL Cloud Infrastructure Implementation

**Date**: November 20, 2025  
**Status**: ✅ Complete  
**Database**: PostgreSQL 16

---

## 🎯 Objective

Update all cloud infrastructure configurations to include PostgreSQL database provisioning, replacing the previous SQLite-only approach with a production-ready database solution across all deployment targets.

## ✅ Implementation Summary

All cloud deployment configurations have been updated to provision and configure PostgreSQL databases:

### 1. Azure Deployment (Ruby Script) ✅

**File**: `infra/deployment/azure/azure_rag_infrastructure.rb`

**Changes**:
- ✅ Added PostgreSQL Flexible Server provisioning
- ✅ Added database creation and configuration
- ✅ Added firewall rules (Azure services + development access)
- ✅ Added connection string generation
- ✅ Added PostgreSQL status checks
- ✅ Updated deployment summary to include database info
- ✅ Added helper methods for PostgreSQL server naming

**New Methods**:
- `create_database()` - Provisions Azure Database for PostgreSQL Flexible Server
- `create_application_database()` - Creates the application database
- `create_database_firewall_rules()` - Configures network access
- `generate_postgres_server_name()` - Generates unique server names
- `generate_secure_password()` - Creates secure passwords

**Features**:
- PostgreSQL 16 (latest)
- Burstable tier (Standard_B1ms) for cost efficiency
- 32GB storage with auto-grow
- SSL/TLS enforced
- Automated backups
- High availability options
- Azure services integration

**Deployment**:
```bash
cd infra/deployment/azure
ruby azure_rag_infrastructure.rb deploy
```

### 2. AWS Infrastructure (Terraform) ✅

**Files Created**:
- `infra/terraform/aws/main.tf` - Complete AWS infrastructure
- `infra/terraform/aws/terraform.tfvars.example` - Configuration template
- `infra/terraform/aws/README.md` - Comprehensive documentation

**Resources Provisioned**:
- ✅ RDS PostgreSQL 16 instance
- ✅ VPC with public/private subnets
- ✅ Security groups for database access
- ✅ S3 bucket for document storage
- ✅ IAM roles for RDS monitoring
- ✅ DB subnet groups
- ✅ Automated backups and monitoring

**Features**:
- Environment-aware configuration (dev/production)
- Enhanced monitoring with CloudWatch
- Encrypted storage at rest
- Automated backups (1-7 days retention)
- Multi-AZ option for production
- Cost-optimized instance sizing

**Deployment**:
```bash
cd infra/terraform/aws
terraform init
terraform apply
```

### 3. GCP Infrastructure (Terraform) ✅

**Files Created**:
- `infra/terraform/gcp/main.tf` - Complete GCP infrastructure
- `infra/terraform/gcp/terraform.tfvars.example` - Configuration template
- `infra/terraform/gcp/README.md` - Comprehensive documentation

**Resources Provisioned**:
- ✅ Cloud SQL PostgreSQL 16 instance
- ✅ VPC network with private IP
- ✅ Cloud Storage bucket for documents
- ✅ Service accounts and IAM bindings
- ✅ Private service connection
- ✅ Automated backups and PITR

**Features**:
- Cloud SQL Proxy support
- Point-in-time recovery
- Regional high availability
- Query insights enabled
- Automated backups
- Private VPC connectivity
- Environment-aware configuration

**Deployment**:
```bash
cd infra/terraform/gcp
terraform init
terraform apply
```

### 4. Docker Compose (Already Complete) ✅

**Files** (No changes needed - already had PostgreSQL):
- `docker-compose.unified.yml` - Single container with PostgreSQL
- `infra/docker/archive-multi-container/docker-compose.yml` - Multi-container with PostgreSQL
- `env.unified.example` - Environment variables with PostgreSQL config

**PostgreSQL Configuration**:
- PostgreSQL 16-alpine image
- Health checks enabled
- Persistent volumes
- Environment-based configuration
- Development and production modes

## 📋 Configuration Summary

### Environment Variables Required

All deployments now require these PostgreSQL environment variables:

```bash
# Connection URL (all-in-one)
DATABASE_URL=postgresql://user:password@host:5432/dbname?sslmode=require

# Individual components
DB_HOST=hostname
DB_PORT=5432
DB_USERNAME=username
DB_PASSWORD=password
DB_NAME=database_name
```

### Provider-Specific Variables

#### Azure
```bash
AZURE_POSTGRES_SERVER=server-name
AZURE_POSTGRES_DATABASE=utsv2
AZURE_POSTGRES_ADMIN=utsv2admin
AZURE_POSTGRES_PASSWORD=secure_password
```

#### AWS
```bash
# Set in terraform.tfvars
db_username = "utsv2admin"
db_password = "secure_password"
db_name     = "utsv2"
```

#### GCP
```bash
# Set in terraform.tfvars
gcp_project_id = "my-project-id"
db_username    = "utsv2admin"
db_password    = "secure_password"
db_name        = "utsv2"
```

## 🏗️ Architecture

### Database Architecture

```
Application Layer
    ├── API (Sinatra)
    ├── Worker (Sidekiq)
    └── Frontend (React)
         ↓
    PostgreSQL 16
    ├── documents table
    ├── users table
    ├── organizations table
    ├── jobs table
    └── settings table
```

### Cloud-Specific Architecture

#### Azure
```
Resource Group
├── PostgreSQL Flexible Server
│   ├── Database: utsv2
│   ├── Firewall Rules
│   └── SSL/TLS Enforced
├── Storage Account (Blobs)
├── AI Search Service
└── OpenAI Service (optional)
```

#### AWS
```
VPC
├── Public Subnets (App Servers)
├── Private Subnets (Database)
├── RDS PostgreSQL
│   ├── Multi-AZ (production)
│   ├── Automated Backups
│   └── Enhanced Monitoring
└── S3 Bucket (Documents)
```

#### GCP
```
Project
├── VPC Network
├── Cloud SQL PostgreSQL
│   ├── Private IP
│   ├── Cloud SQL Proxy
│   ├── PITR Enabled
│   └── Query Insights
└── Cloud Storage (Documents)
```

## 🔒 Security Features

### All Providers

- ✅ SSL/TLS enforced connections
- ✅ Encrypted storage at rest
- ✅ Network isolation (VPC/private subnets)
- ✅ Automated security patches
- ✅ Password complexity requirements
- ✅ Audit logging enabled

### Development vs Production

| Feature | Development | Production |
|---------|-------------|------------|
| Public Access | ✅ Enabled | ❌ Disabled |
| Firewall | Open (0.0.0.0/0) | VPC/VPN only |
| Backup Retention | 1 day | 7+ days |
| High Availability | Single zone | Multi-zone |
| Deletion Protection | ❌ Disabled | ✅ Enabled |
| Monitoring | Basic | Enhanced |

## 💰 Cost Estimates

### Monthly Costs (Approximate)

| Provider | Development | Production |
|----------|-------------|------------|
| **Azure** | $12-15 | $50-80 |
| **AWS** | $15-20 | $35-60 |
| **GCP** | $10-15 | $120-150 |
| **Docker** | $0 (local) | $0 (self-hosted) |

**Notes**:
- Development uses minimal instance sizes
- Production includes backups, monitoring, HA
- Costs vary by region and usage
- Storage and data transfer additional

## 📊 Performance Specifications

### Instance Sizes

#### Azure
- **Dev**: Standard_B1ms (1 vCore, 2GB RAM)
- **Prod**: Standard_D2s_v3 (2 vCore, 8GB RAM)

#### AWS
- **Dev**: db.t3.micro (2 vCPU, 1GB RAM)
- **Prod**: db.t3.small (2 vCPU, 2GB RAM)

#### GCP
- **Dev**: db-f1-micro (shared, 0.6GB RAM)
- **Prod**: db-custom-2-4096 (2 vCPU, 4GB RAM)

### Storage

| Provider | Storage | IOPS | Type |
|----------|---------|------|------|
| Azure | 32GB (auto-grow) | Variable | Premium SSD |
| AWS | 20GB (auto-grow) | 3000 | gp3 |
| GCP | 20GB (auto-grow) | Variable | SSD |

## 🚀 Deployment Guide

### Quick Start by Provider

#### Azure
```bash
cd infra/deployment/azure
cp .env.example .env
# Edit .env with Azure credentials
ruby azure_rag_infrastructure.rb deploy
# Note the database connection info from output
```

#### AWS
```bash
cd infra/terraform/aws
cp terraform.tfvars.example terraform.tfvars
# Edit terraform.tfvars
terraform init
terraform plan
terraform apply
# Get connection string
terraform output -raw database_url
```

#### GCP
```bash
cd infra/terraform/gcp
cp terraform.tfvars.example terraform.tfvars
# Edit terraform.tfvars (set gcp_project_id!)
terraform init
terraform plan
terraform apply
# Get connection string
terraform output -raw database_url
```

#### Docker
```bash
cd /path/to/UTSv2_0
cp env.unified.example .env
# Edit .env with settings
docker-compose -f docker-compose.unified.yml up
```

### Connection Testing

Test PostgreSQL connectivity:

```bash
# Using psql
psql "postgresql://user:pass@host:5432/dbname?sslmode=require"

# Using Ruby
ruby -e "require 'pg'; PG.connect(ENV['DATABASE_URL']); puts 'Connected!'"

# From application
bundle exec rake db:migrate
```

## 🔧 Maintenance

### Backups

All cloud providers include automated backups:

- **Azure**: Automated backups, 7-35 day retention
- **AWS**: Automated backups, configurable retention
- **GCP**: Automated backups, point-in-time recovery

### Manual Backups

```bash
# Create backup
pg_dump "postgresql://user:pass@host:5432/dbname" > backup.sql

# Restore backup
psql "postgresql://user:pass@host:5432/dbname" < backup.sql
```

### Monitoring

#### Azure
```bash
# View metrics
az postgres flexible-server show --name SERVER --resource-group RG

# View logs
az postgres flexible-server logs list --name SERVER --resource-group RG
```

#### AWS
```bash
# CloudWatch metrics in AWS Console
# Or use AWS CLI
aws rds describe-db-instances --db-instance-identifier INSTANCE
```

#### GCP
```bash
# Cloud Console > Cloud SQL > Instance
# Or use gcloud
gcloud sql instances describe INSTANCE
```

### Scaling

All providers support vertical scaling (instance size) and horizontal scaling (read replicas).

#### Vertical Scaling (Bigger Instance)

- **Azure**: Change tier/SKU in portal or CLI
- **AWS**: Modify instance class
- **GCP**: Change machine type

#### Horizontal Scaling (Read Replicas)

```bash
# Azure
az postgres flexible-server replica create --replica-name REPLICA --source-server SOURCE

# AWS
aws rds create-db-instance-read-replica --db-instance-identifier REPLICA --source-db-instance-identifier SOURCE

# GCP
gcloud sql instances create REPLICA --master-instance-name=SOURCE
```

## 📚 Documentation Files

### Created/Updated

1. ✅ `infra/README.md` - Infrastructure overview
2. ✅ `infra/terraform/aws/main.tf` - AWS Terraform config
3. ✅ `infra/terraform/aws/README.md` - AWS documentation
4. ✅ `infra/terraform/aws/terraform.tfvars.example` - AWS variables
5. ✅ `infra/terraform/gcp/main.tf` - GCP Terraform config
6. ✅ `infra/terraform/gcp/README.md` - GCP documentation
7. ✅ `infra/terraform/gcp/terraform.tfvars.example` - GCP variables
8. ✅ `infra/deployment/azure/azure_rag_infrastructure.rb` - Updated with PostgreSQL
9. ✅ `docs/POSTGRES_CLOUD_INFRASTRUCTURE.md` - This document

### Existing (No Changes Needed)

- ✅ `docker-compose.unified.yml` - Already had PostgreSQL
- ✅ `infra/docker/archive-multi-container/docker-compose.yml` - Already had PostgreSQL
- ✅ `env.unified.example` - Already had PostgreSQL config
- ✅ `config/database.yml` - PostgreSQL configuration
- ✅ `config/database.rb` - Database connection setup

## 🧪 Testing

### Verify Deployments

#### Azure
```bash
cd infra/deployment/azure
ruby azure_rag_infrastructure.rb status
```

#### AWS
```bash
cd infra/terraform/aws
terraform show
aws rds describe-db-instances
```

#### GCP
```bash
cd infra/terraform/gcp
terraform show
gcloud sql instances list
```

#### Docker
```bash
docker-compose -f docker-compose.unified.yml ps
docker exec utsv2_postgres psql -U utsv2 -d utsv2_development -c "SELECT version();"
```

### Run Migrations

```bash
# Set DATABASE_URL from provider output
export DATABASE_URL="postgresql://..."

# Run migrations
bundle exec rake db:migrate

# Verify
bundle exec rake db:version
```

### Application Testing

```bash
# Start application
bundle exec puma -C config/puma.rb

# Test API
curl http://localhost:9292/api/health

# Test database connection
curl http://localhost:9292/api/documents
```

## 🐛 Troubleshooting

### Common Issues

#### Can't connect to database

**Symptoms**: Connection refused, timeout errors

**Solutions**:
1. Check firewall/security group rules
2. Verify SSL/TLS settings (`?sslmode=require`)
3. Confirm database is running
4. Check credentials
5. Test with `psql` directly

#### Migrations fail

**Symptoms**: Migration errors, permission denied

**Solutions**:
1. Verify user has CREATE permission
2. Check PostgreSQL version (need 12+)
3. Review migration file syntax
4. Check connection string format

#### Performance issues

**Symptoms**: Slow queries, timeouts

**Solutions**:
1. Check instance size
2. Review slow query logs
3. Add indexes where needed
4. Enable connection pooling
5. Scale up instance

#### Out of storage

**Symptoms**: Disk full errors

**Solutions**:
1. All providers have auto-grow enabled
2. Manually increase if needed
3. Review data retention policies
4. Archive old data

## 🔄 Migration from SQLite

If you're migrating from SQLite to PostgreSQL:

1. **Export SQLite data**:
   ```bash
   ruby script/utilities/export_sqlite_data.rb
   ```

2. **Deploy PostgreSQL** (choose provider)

3. **Run migrations**:
   ```bash
   DATABASE_URL="postgresql://..." bundle exec rake db:migrate
   ```

4. **Import data**:
   ```bash
   ruby script/utilities/import_to_postgres.rb
   ```

5. **Verify**:
   ```bash
   bundle exec rake db:version
   psql $DATABASE_URL -c "SELECT COUNT(*) FROM documents;"
   ```

## ✅ Checklist

### Deployment Checklist

- [ ] Choose cloud provider (Azure/AWS/GCP/Docker)
- [ ] Set up cloud account and credentials
- [ ] Copy and configure variables file
- [ ] Review security settings
- [ ] Deploy infrastructure
- [ ] Note connection information
- [ ] Update application .env file
- [ ] Run database migrations
- [ ] Test database connectivity
- [ ] Test application functionality
- [ ] Set up monitoring/alerts
- [ ] Configure automated backups
- [ ] Document credentials securely

### Production Checklist

- [ ] Remove public database access
- [ ] Restrict firewall to VPC/VPN only
- [ ] Use secrets manager for credentials
- [ ] Enable deletion protection
- [ ] Configure automated backups (7+ days)
- [ ] Set up monitoring and alerts
- [ ] Enable SSL/TLS enforcement
- [ ] Review and harden security groups
- [ ] Set up read replicas (if needed)
- [ ] Configure high availability
- [ ] Test disaster recovery procedure
- [ ] Document runbook procedures

## 📞 Support

### Resources

- **Project README**: [README.md](../README.md)
- **Database Schema**: [db/schema.sql](../db/schema.sql)
- **Infrastructure Overview**: [infra/README.md](../infra/README.md)
- **Docker Guide**: [infra/docker/README.unified.md](../infra/docker/README.unified.md)

### Provider Documentation

- [Azure Database for PostgreSQL](https://learn.microsoft.com/en-us/azure/postgresql/)
- [AWS RDS PostgreSQL](https://docs.aws.amazon.com/AmazonRDS/latest/UserGuide/CHAP_PostgreSQL.html)
- [GCP Cloud SQL PostgreSQL](https://cloud.google.com/sql/docs/postgres)
- [PostgreSQL Documentation](https://www.postgresql.org/docs/16/)

### Tools

- [pgAdmin](https://www.pgadmin.org/) - PostgreSQL GUI
- [DBeaver](https://dbeaver.io/) - Universal database tool
- [Terraform](https://www.terraform.io/) - Infrastructure as code
- [Azure CLI](https://docs.microsoft.com/en-us/cli/azure/) - Azure command line

## 🎉 Conclusion

All cloud infrastructure configurations have been successfully updated to include PostgreSQL database provisioning. The application now has consistent, production-ready database infrastructure across all deployment targets:

- ✅ Azure (Ruby scripts)
- ✅ AWS (Terraform)
- ✅ GCP (Terraform)
- ✅ Docker (Compose)

Each configuration includes:
- PostgreSQL 16 (latest stable)
- Automated backups
- SSL/TLS encryption
- Environment-aware settings
- Comprehensive documentation
- Cost optimization
- Security best practices

The infrastructure is ready for production deployments! 🚀

---

**Document Version**: 1.0  
**Last Updated**: 2025-11-20  
**Author**: AI Assistant  
**Status**: Complete ✅

