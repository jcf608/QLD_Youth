# UTSv2 Infrastructure

This directory contains all infrastructure-as-code (IaC) configurations for deploying UTSv2 across different environments and cloud providers.

## 📁 Directory Structure

```
infra/
├── deployment/          # Ruby-based deployment scripts
│   ├── azure/          # Azure deployment automation
│   └── common/         # Shared base infrastructure code
├── docker/             # Docker configurations
│   ├── Dockerfile.unified              # Single-container deployment
│   ├── nginx.unified.conf             # Nginx configuration
│   ├── supervisord.conf               # Process supervisor
│   └── archive-multi-container/       # Multi-container setup (archived)
├── terraform/          # Terraform configurations
│   ├── aws/           # AWS infrastructure (RDS PostgreSQL)
│   └── gcp/           # GCP infrastructure (Cloud SQL PostgreSQL)
└── scripts/           # Deployment helper scripts
```

## 🗄️ Database: PostgreSQL

**All cloud configurations now include PostgreSQL as the database backend.**

The application uses PostgreSQL 16 for:
- Transactional data storage
- Document metadata
- User management
- Job queues (via Sidekiq + Redis)

## 🚀 Deployment Options

### 1. Docker Compose (Development & Production)

**Recommended for**: Local development, single-server deployments, quick testing

#### Unified Container (Simplest)
- Single container with all services
- Includes PostgreSQL, Redis, API, Worker, and Frontend
- Managed by supervisord

```bash
# From project root
docker-compose -f docker-compose.unified.yml up
```

See: [docker-compose.unified.yml](../docker-compose.unified.yml) and [docker/README.unified.md](docker/README.unified.md)

#### Multi-Container (Development)
- Separate containers for each service
- Better for development and debugging

```bash
# From project root
docker-compose -f infra/docker/archive-multi-container/docker-compose.yml up
```

See: [docker/archive-multi-container/](docker/archive-multi-container/)

### 2. Azure (Ruby Scripts)

**Recommended for**: Azure subscriptions, especially student accounts

Automated deployment script that provisions:
- Azure Database for PostgreSQL Flexible Server
- Azure Storage (blob storage for documents)
- Azure AI Search (vector database)
- Azure OpenAI (optional, or use external OpenAI API)

```bash
cd infra/deployment/azure
ruby azure_rag_infrastructure.rb deploy
```

**Features:**
- ✅ Automatic region validation
- ✅ Student subscription support
- ✅ Flexible OpenAI provider (Azure or external)
- ✅ Complete environment configuration output
- ✅ PostgreSQL with automatic firewall rules

See: [deployment/azure/](deployment/azure/)

### 3. AWS (Terraform)

**Recommended for**: AWS deployments, teams using Terraform

Terraform configuration that provisions:
- RDS PostgreSQL 16
- S3 bucket for documents
- VPC with public/private subnets
- Security groups and IAM roles

```bash
cd infra/terraform/aws
terraform init
terraform apply
```

**Features:**
- ✅ Environment-aware configuration
- ✅ High availability options
- ✅ Automated backups
- ✅ Enhanced monitoring

See: [terraform/aws/README.md](terraform/aws/README.md)

### 4. GCP (Terraform)

**Recommended for**: GCP deployments, Google Cloud Platform projects

Terraform configuration that provisions:
- Cloud SQL PostgreSQL 16
- Cloud Storage for documents
- VPC network
- Service accounts and IAM

```bash
cd infra/terraform/gcp
terraform init
terraform apply
```

**Features:**
- ✅ Cloud SQL with private VPC
- ✅ Cloud SQL Proxy support
- ✅ Point-in-time recovery
- ✅ Regional high availability

See: [terraform/gcp/README.md](terraform/gcp/README.md)

## 🏗️ Architecture Overview

### Application Components

```
┌─────────────────────────────────────────────────────┐
│                   Load Balancer                      │
│              (nginx/Cloud LB/ALB)                   │
└─────────────────┬───────────────────────────────────┘
                  │
         ┌────────┴────────┐
         │                 │
    ┌────▼─────┐     ┌────▼─────┐
    │   API    │     │ Frontend │
    │ (Sinatra)│     │  (React) │
    └────┬─────┘     └──────────┘
         │
    ┌────▼─────┐
    │  Worker  │
    │(Sidekiq) │
    └────┬─────┘
         │
    ┌────┴────────────┬──────────┐
    │                 │          │
┌───▼────┐      ┌────▼─────┐ ┌─▼────────┐
│ Postgres│      │  Redis   │ │  Storage │
│   DB    │      │  Cache   │ │(S3/Blob) │
└─────────┘      └──────────┘ └──────────┘
```

### Database Schema

PostgreSQL stores:
- **documents**: Metadata, content, provenance
- **users**: Authentication, permissions
- **organizations**: Multi-tenant support
- **jobs**: Background job metadata
- **settings**: Application configuration

See: [../db/schema.sql](../db/schema.sql)

## 🔧 Configuration

### Environment Variables

All deployments require these environment variables:

#### Database (PostgreSQL)
```bash
DATABASE_URL=postgresql://user:password@host:5432/dbname?sslmode=require
DB_HOST=hostname
DB_PORT=5432
DB_USERNAME=username
DB_PASSWORD=password
DB_NAME=database_name
```

#### Redis (Job Queue)
```bash
REDIS_URL=redis://localhost:6379/0
```

#### Storage (Cloud Provider)
```bash
# AWS
AWS_ACCESS_KEY_ID=your_key
AWS_SECRET_ACCESS_KEY=your_secret
AWS_REGION=us-east-1

# Azure
AZURE_STORAGE_ACCOUNT=account_name
AZURE_STORAGE_KEY=account_key

# GCP
GOOGLE_CLOUD_PROJECT=project-id
GOOGLE_APPLICATION_CREDENTIALS=/path/to/creds.json
```

#### AI Services
```bash
# OpenAI API
OPENAI_API_KEY=sk-...

# Azure OpenAI (optional)
AZURE_OPENAI_API_KEY=key
AZURE_OPENAI_ENDPOINT=https://...
```

### Example Files

- [../env.unified.example](../env.unified.example) - Docker unified deployment
- [terraform/aws/terraform.tfvars.example](terraform/aws/terraform.tfvars.example) - AWS Terraform
- [terraform/gcp/terraform.tfvars.example](terraform/gcp/terraform.tfvars.example) - GCP Terraform

## 📊 Database Migration

### From SQLite to PostgreSQL

If you're migrating from a previous SQLite setup:

1. **Export SQLite data:**
   ```bash
   ruby script/utilities/export_sqlite_data.rb
   ```

2. **Deploy PostgreSQL infrastructure** (choose one):
   - Docker: `docker-compose up postgres`
   - Azure: `ruby infra/deployment/azure/azure_rag_infrastructure.rb deploy`
   - AWS: `cd infra/terraform/aws && terraform apply`
   - GCP: `cd infra/terraform/gcp && terraform apply`

3. **Run migrations:**
   ```bash
   DATABASE_URL=postgresql://... bundle exec rake db:migrate
   ```

4. **Import data:**
   ```bash
   ruby script/utilities/import_to_postgres.rb
   ```

### Creating New Migrations

```bash
# Create a new migration
cd db/migrate
# Create a new file: NNNN_description.rb

# Run migrations
bundle exec rake db:migrate

# Rollback if needed
bundle exec rake db:rollback
```

See: [../db/README.md](../db/README.md)

## 🔒 Security Considerations

### Development vs Production

#### Development ✅ Allowed:
- Public database access
- Open security groups/firewall rules
- Sample/test credentials
- Unencrypted connections (but SSL preferred)

#### Production ⚠️ Required:
- Private database access (VPN/VPC only)
- Restrictive security groups
- Strong passwords in secrets manager
- SSL/TLS enforced
- Automated backups enabled
- Monitoring and alerting configured

### Secrets Management

**Never commit secrets to git!**

Use:
- **AWS**: AWS Secrets Manager or Parameter Store
- **Azure**: Azure Key Vault
- **GCP**: Secret Manager
- **Docker**: Docker secrets or environment files (not in repo)

## 📈 Monitoring

### Database Monitoring

#### AWS CloudWatch
- RDS metrics automatically collected
- Enhanced monitoring available
- CloudWatch Logs for PostgreSQL logs

#### Azure Monitor
- Metrics for PostgreSQL Flexible Server
- Query Performance Insight
- Diagnostic logs

#### GCP Cloud Monitoring
- Cloud SQL insights enabled
- Query performance metrics
- Automatic alerting

### Application Monitoring

Consider adding:
- **NewRelic** or **DataDog** for APM
- **Sentry** for error tracking
- **Prometheus + Grafana** for custom metrics

## 💰 Cost Optimization

### Development

| Provider | Service | Cost/Month |
|----------|---------|------------|
| AWS | db.t3.micro RDS | ~$15 |
| Azure | Burstable PostgreSQL | ~$12 |
| GCP | db-f1-micro | ~$10 |
| Docker | Local (free) | $0 |

### Production

| Provider | Service | Cost/Month |
|----------|---------|------------|
| AWS | db.t3.small RDS | ~$30 |
| Azure | Standard PostgreSQL | ~$50 |
| GCP | db-custom-2-4096 | ~$115 |

**Tips:**
- Use reserved instances for 30-50% savings
- Enable auto-scaling for variable workloads
- Set up cost alerts
- Review unused resources monthly

## 🆘 Troubleshooting

### Can't Connect to Database

1. **Check connection string format:**
   ```bash
   postgresql://username:password@host:port/database?sslmode=require
   ```

2. **Verify firewall/security groups** allow your IP

3. **Test connection:**
   ```bash
   psql "postgresql://user:pass@host:5432/dbname?sslmode=require"
   ```

4. **Check database is running:**
   - Docker: `docker ps`
   - AWS: Check RDS console
   - Azure: Check Portal
   - GCP: Check Console

### Migrations Fail

1. **Check database permissions**
2. **Verify PostgreSQL version** (requires 12+, recommend 16)
3. **Review migration file** for syntax errors
4. **Check logs**: `tail -f log/production.log`

### Performance Issues

1. **Enable query logging**
2. **Check connection pooling** (use PgBouncer)
3. **Review slow queries**
4. **Add indexes** where needed
5. **Scale up instance size**

## 📚 Additional Resources

### Documentation
- [Project README](../README.md)
- [Database Schema](../docs/DATABASE_SCHEMA.md)
- [API Documentation](../docs/api/)
- [Docker Guide](../docker/README.unified.md)

### Cloud Provider Docs
- [AWS RDS PostgreSQL](https://docs.aws.amazon.com/AmazonRDS/latest/UserGuide/CHAP_PostgreSQL.html)
- [Azure Database for PostgreSQL](https://learn.microsoft.com/en-us/azure/postgresql/)
- [GCP Cloud SQL PostgreSQL](https://cloud.google.com/sql/docs/postgres)

### Tools
- [PostgreSQL Documentation](https://www.postgresql.org/docs/)
- [Terraform Registry](https://registry.terraform.io/)
- [Docker Documentation](https://docs.docker.com/)

## 🤝 Contributing

When adding new infrastructure:

1. **Test locally with Docker first**
2. **Document all environment variables**
3. **Provide example configuration files**
4. **Include cost estimates**
5. **Update this README**

## 📧 Support

For infrastructure questions:
- Review relevant README in subdirectories
- Check cloud provider documentation
- Review application logs
- Consult with DevOps team

---

**Last Updated**: 2025-11-20
**PostgreSQL Version**: 16
**Supported Clouds**: AWS, Azure, GCP, Docker

