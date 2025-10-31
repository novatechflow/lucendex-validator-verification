-- Lucendex Database Initialization
-- This script runs automatically when PostgreSQL container first starts
-- It sets up schemas, roles, and applies all migrations

\echo 'Initializing Lucendex database...'

-- Create schemas
CREATE SCHEMA IF NOT EXISTS core;
CREATE SCHEMA IF NOT EXISTS metering;

\echo '✓ Schemas created'

-- Create audit trigger function (used by all tables)
CREATE OR REPLACE FUNCTION core.audit_trigger_func()
RETURNS TRIGGER AS $$
BEGIN
    IF (TG_OP = 'INSERT') THEN
        NEW.created_at = COALESCE(NEW.created_at, now());
        NEW.updated_at = now();
        RETURN NEW;
    ELSIF (TG_OP = 'UPDATE') THEN
        NEW.updated_at = now();
        RETURN NEW;
    END IF;
    RETURN NULL;
END;
$$ LANGUAGE plpgsql;

\echo '✓ Audit function created'

-- Enable extensions
CREATE EXTENSION IF NOT EXISTS pgcrypto;

\echo '✓ Extensions enabled'

-- Note: Role creation with passwords must be done via environment variables
-- The roles (indexer_rw, router_ro, api_ro) are created by the deployment script
-- using the passwords from .env file

\echo 'Database initialization complete'
\echo 'Run migrations from backend/db/migrations/ to create tables'
