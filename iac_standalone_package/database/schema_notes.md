# Database Schema for Cloud Infrastructure

## Tables Used by IaC System

### audit_logs
Tracks all cloud deployment and destruction activities.

```sql
CREATE TABLE audit_logs (
    id bigint NOT NULL,
    user_id bigint,
    action character varying NOT NULL,
    resource_type character varying,
    resource_id bigint,
    ip_address character varying,
    user_agent character varying,
    change_data jsonb,
    metadata jsonb,
    status character varying NOT NULL,
    error_message text,
    created_at timestamp(6) without time zone NOT NULL
);
```

### capability_registrations
Stores cloud provider capabilities and service availability.

```sql
CREATE TABLE capability_registrations (
    id bigint NOT NULL,
    provider character varying NOT NULL,
    capability_tag character varying NOT NULL,
    mime_patterns character varying[] DEFAULT '{}'::character varying[],
    region character varying,
    latency_p50 double precision,
    latency_p95 double precision,
    last_verified_at timestamp(6) without time zone,
    created_by_id bigint,
    updated_by_id bigint,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);
```

### Related Tables
- documents (status reset after cloud destruction)
- document_versions (source_cloud column)
- document_chunks (deleted during cleanup)
- document_embeddings (deleted during cleanup)
- document_index_entries (provider column, deleted during cleanup)
- processing_jobs (provider column, deleted during cleanup)

## Notes
The IaC system primarily uses Redis for deployment tracking (temporary state)
and the audit_logs table for permanent records. Most cloud infrastructure
state is managed directly in the cloud provider.
