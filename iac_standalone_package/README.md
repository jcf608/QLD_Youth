# Infrastructure as Code (IaC) Standalone Package

This package contains all the components needed to implement Infrastructure as Code deployment functionality as a standalone application.

## 📋 Contents

### Backend Components (`/backend`)

#### Routes (`/backend/routes`)
- **cloud_deployment_routes.rb** - API endpoints for cloud deployment
  - `POST /api/v1/cloud/deploy` - Start deployment
  - `GET /api/v1/cloud/deploy/:id/status` - Check deployment status
  - `POST /api/v1/cloud/test` - Test cloud credentials
  - `GET /api/v1/cloud/resources` - List deployed resources
  - `POST /api/v1/cloud/destroy` - Destroy infrastructure

#### Services (`/backend/services`)
- **cloud_deployment_service.rb** - Core deployment logic for Azure
- **database_backup_service.rb** - Database backup before destruction
- **base_service.rb** - Base service class pattern

#### Workers (`/backend/workers`)
- **cloud_deployment_worker.rb** - Async deployment with Sidekiq

#### Providers (`/backend/providers`)
- **base_cloud_provider.rb** - Abstract base class for cloud providers
- **azure_cloud_provider.rb** - Azure implementation
- **provider_factory.rb** - Factory pattern for provider instantiation

#### Domain (`/backend/domain`)
- **audit_log.rb** - Audit logging domain model

### Frontend Components (`/frontend`)

#### Services (`/frontend/services`)
- **cloudDeployment.ts** - Client-side cloud deployment service
  - Deployment initiation
  - Status polling
  - Resource management
  - Destruction operations

- **api.ts** - API client configuration

#### Pages (`/frontend/pages`)
- **SettingsPage.tsx** - Cloud infrastructure management UI
  - Provider selection (Azure/AWS/GCP)
  - Deployment interface
  - Resource visualization
  - Destruction controls

### Infrastructure (`/infrastructure`)

#### Ruby-based Deployment (`/infrastructure/deployment`)
- **azure/azure_rag_infrastructure.rb** - Complete Azure deployment script
  - Resource group creation
  - PostgreSQL database setup
  - Storage account & containers
  - AI Search service
  - Azure OpenAI service (optional)
  - Region validation
  - Security configuration

- **common/base_infrastructure.rb** - Template pattern base class

#### Terraform (`/infrastructure/terraform`)
- **aws/** - AWS Terraform configuration for RDS PostgreSQL
- **gcp/** - GCP Terraform configuration for Cloud SQL PostgreSQL

### Database (`/database`)
- **schema_notes.md** - Database tables and schema information
  - audit_logs
  - capability_registrations
  - Related tables

### Documentation (`/docs`)
- **POSTGRES_CLOUD_INFRASTRUCTURE.md** - PostgreSQL infrastructure guide
- **CLOUD_INFRASTRUCTURE_REFACTOR.md** - Architecture and design decisions
- **CLOUD_DESTROY_HANDOFF.md** - Destruction workflow documentation

## 🏗️ Architecture

### Deployment Flow

1. **Frontend** → User initiates deployment via SettingsPage
2. **API Route** → cloud_deployment_routes.rb receives request
3. **Worker** → CloudDeploymentWorker queues async job (Sidekiq)
4. **Service** → CloudDeploymentService executes deployment
5. **Provider** → AzureCloudProvider interacts with Azure CLI
6. **Status** → Progress stored in Redis, polled by frontend

### Destruction Flow

1. **Database Backup** → DatabaseBackupService creates provenance backup
2. **Cloud Destruction** → Provider destroys resource group
3. **Database Cleanup** → Remove orphaned RAG data (chunks, embeddings, indexes)
4. **Audit Log** → Record destruction with backup info

## 🚀 Key Features

### Multi-Cloud Support
- Azure (fully implemented)
- AWS (Terraform ready)
- GCP (Terraform ready)

### Async Deployment
- Background jobs with Sidekiq
- Real-time progress updates via Redis
- Polling-based status checks

### Safety Features
- Automatic database backup before destruction
- Confirmation dialogs
- Audit logging
- Graceful error handling

### Region Intelligence
- Automatic region validation
- Service availability checking
- Subscription policy detection
- Azure OpenAI quota verification
- Model availability validation

### Database Management
- Selective backup (provenance only)
- Smart cleanup (removes RAG infra, keeps provenance)
- Referential integrity maintenance

## 📦 Dependencies

### Backend
- Ruby 3.x
- Sinatra (web framework)
- Sidekiq (background jobs)
- Redis (job queue & deployment state)
- Azure CLI (`az`)
- PostgreSQL client (`pg` gem)

### Frontend
- React 18
- TypeScript
- Axios (HTTP client)
- React Router

### Cloud
- Azure CLI
- AWS CLI (for Terraform)
- GCP CLI (for Terraform)
- Terraform (for AWS/GCP PostgreSQL)

## 🔧 Configuration

### Environment Variables

```bash
# Azure Configuration
AZURE_SUBSCRIPTION_ID=your-subscription-id
AZURE_TENANT_ID=your-tenant-id
AZURE_RESOURCE_GROUP_PREFIX=UTS  # Filter resource groups
AZURE_LOCATION=eastus

# OpenAI (if using external API instead of Azure OpenAI)
OPENAI_API_KEY=sk-...
AI_PROVIDER=openai  # or 'azure_openai'

# Database
DATABASE_URL=postgresql://user:pass@host:5432/dbname
```

### Provider Configuration

Providers are selected via environment variables:
- `PREFERRED_STORAGE_PROVIDER` (default: azure)
- `PREFERRED_EMBEDDER_PROVIDER` (default: openai)
- `PREFERRED_INDEXER_PROVIDER` (default: local)

## 🎯 Integration Points

### With Main Application

If integrating into an existing app:

1. **API Integration**
   - Mount routes under `/api/v1/cloud`
   - Ensure authentication middleware
   - Configure Sidekiq workers

2. **Database Integration**
   - Run migrations for audit_logs and capability_registrations
   - Configure document cleanup hooks

3. **Frontend Integration**
   - Add CloudDeploymentService to services
   - Include SettingsPage or embed components
   - Configure API client base URL

### As Standalone Application

To run as a standalone service:

1. **Setup Sinatra app** with cloud_deployment_routes
2. **Configure Redis** for Sidekiq and deployment state
3. **Setup PostgreSQL** for audit logs
4. **Mount frontend** as React SPA
5. **Configure authentication** (JWT, session, etc.)

## 📝 API Reference

### Deploy Infrastructure
```http
POST /api/v1/cloud/deploy
Content-Type: application/json

{
  "provider": "azure",
  "resource_group": "optional-custom-name",
  "location": "eastus"
}

Response: 202 Accepted
{
  "success": true,
  "data": {
    "deployment_id": "deploy_1234567890_abc123",
    "message": "Deployment started",
    "status_url": "/api/v1/cloud/deploy/deploy_1234567890_abc123/status"
  }
}
```

### Check Deployment Status
```http
GET /api/v1/cloud/deploy/:deployment_id/status

Response: 200 OK
{
  "success": true,
  "data": {
    "status": "in_progress",  // or "completed", "failed"
    "message": "Creating storage account...",
    "data": null  // Resources array when completed
  }
}
```

### List Resources
```http
GET /api/v1/cloud/resources?provider=azure

Response: 200 OK
{
  "success": true,
  "data": {
    "resource_groups": [
      {
        "name": "UTS-DEV-RG",
        "location": "eastus",
        "resource_count": 5,
        "resources": [...]
      }
    ]
  }
}
```

### Destroy Infrastructure
```http
POST /api/v1/cloud/destroy
Content-Type: application/json

{
  "provider": "azure",
  "resource_group": "UTS-DEV-RG"
}

Response: 200 OK
{
  "success": true,
  "data": {
    "message": "Resource group deletion initiated",
    "backup_file": "/tmp/backups/provenance_backup_20250101_120000.sql",
    "backup_size": "2.34 MB",
    "database_cleanup": {
      "chunks_deleted": 150,
      "index_entries_deleted": 10,
      "processing_jobs_deleted": 5
    }
  }
}
```

## 🛠️ Development Guide

### Running Locally

1. **Start Redis**
   ```bash
   redis-server
   ```

2. **Start Sidekiq**
   ```bash
   bundle exec sidekiq -r ./backend/workers/cloud_deployment_worker.rb
   ```

3. **Start API**
   ```bash
   bundle exec ruby backend/api.rb
   ```

4. **Start Frontend**
   ```bash
   cd frontend && npm run dev
   ```

### Testing Deployment

1. **Test Azure CLI**
   ```bash
   az login
   az account show
   ```

2. **Test Connection** via API
   ```bash
   curl -X POST http://localhost:9292/api/v1/cloud/test \
     -H "Content-Type: application/json" \
     -d '{"provider":"azure"}'
   ```

3. **Deploy Test Infrastructure**
   - Use Settings page UI
   - Or call API directly
   - Monitor logs for progress

## 📚 Additional Resources

- [Azure CLI Documentation](https://docs.microsoft.com/en-us/cli/azure/)
- [Terraform Documentation](https://www.terraform.io/docs)
- [Sidekiq Documentation](https://github.com/mperham/sidekiq/wiki)
- [React Documentation](https://reactjs.org/docs)

## 🤝 Contributing

When extending this package:

1. **Add New Provider**
   - Extend BaseCloudProvider
   - Implement required methods
   - Add to ProviderFactory
   - Update frontend provider dropdown

2. **Add New Resource Type**
   - Update deployment service
   - Add to infrastructure script
   - Update cleanup logic
   - Document in schema

3. **Improve UI**
   - Enhance SettingsPage components
   - Add resource-specific details
   - Improve error messages
   - Add loading states

## 📄 License

This package is extracted from UTSv2 (Universal Text System v2.0).
Refer to the original project for licensing information.

## ✨ Credits

Developed as part of the UTSv2 project.
Infrastructure deployment follows cloud-agnostic principles with provider-specific implementations.
