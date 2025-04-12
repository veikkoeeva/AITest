#!/bin/bash
set -e

echo "[Setup] Starting custom PostgreSQL initialization..."

PGDATA="${PGDATA:-/var/lib/postgresql/data}"
LOCK_FILE="$PGDATA/.init_done"

# If initialization has been done already, just start PostgreSQL.
if [ -f "$LOCK_FILE" ]; then
  echo "[Setup] Initialization already completed. Starting PostgreSQL..."
  exec postgres
fi

# If PostgreSQL data directory needs to be initialized.
if [ ! -s "$PGDATA/PG_VERSION" ]; then
    echo "[Setup] Initializing database..."
    initdb --username=postgres
    
    # Ensure shared_preload_libraries and other DuckDB settings are configured
    echo "[Setup] Configuring shared_preload_libraries and DuckDB settings..."
    echo "# DuckDB configuration" >> "$PGDATA/postgresql.conf"
    echo "shared_preload_libraries = 'pg_duckdb'" >> "$PGDATA/postgresql.conf"
    echo "duckdb.allow_unsigned_extensions = true" >> "$PGDATA/postgresql.conf"
    echo "duckdb.extension_directory = '/var/lib/postgresql/duckdb_extensions'" >> "$PGDATA/postgresql.conf"
    echo "duckdb.extensions = 'duckpgq'" >> "$PGDATA/postgresql.conf"
     
fi

# Update pg_hba.conf for trusted local connections.
if [ -f "$PGDATA/pg_hba.conf" ]; then
    echo "[Setup] Updating pg_hba.conf..."
    cat > "$PGDATA/pg_hba.conf" <<'EOL'
# Trust authentication for local connections only
local   all   all   trust
# Allow connections from Docker network
host    all   all   172.17.0.0/16  trust
host    all   all   ::1/128        trust
# Deny everything else
host    all   all   0.0.0.0/0      reject
EOL
fi

# Start PostgreSQL.
echo "[Setup] Starting PostgreSQL for initialization..."
pg_ctl -D "$PGDATA" -o "-c listen_addresses='*'" -w start

# Wait for PostgreSQL to be ready.
until pg_isready --username=postgres --host=localhost; do
    echo "[Setup] Waiting for PostgreSQL to be ready..."
    sleep 2
done

# Create database and extensions.
echo "[Setup] Creating database and extensions..."
psql --command="CREATE DATABASE devaitest;"
psql --command="ALTER DATABASE devaitest OWNER TO postgres;"

# Create topology schema first.
psql --dbname=devaitest --command="CREATE SCHEMA IF NOT EXISTS topology;"

# Create extensions.
psql --dbname=devaitest <<EOF
CREATE EXTENSION IF NOT EXISTS postgis SCHEMA public;
CREATE EXTENSION IF NOT EXISTS postgis_raster SCHEMA public;
CREATE EXTENSION IF NOT EXISTS postgis_topology SCHEMA topology;
CREATE EXTENSION IF NOT EXISTS vector SCHEMA public;
CREATE EXTENSION IF NOT EXISTS pg_duckdb SCHEMA public;
EOF

# Install and load DuckPGQ extension.
echo "[Setup] Installing DuckPGQ extension..."
psql --dbname=devaitest --command="SELECT duckdb.raw_query('INSTALL duckpgq FROM community;');"
psql --dbname=devaitest --command="SELECT duckdb.raw_query('LOAD duckpgq;');"

# Mark initialization as done.
touch "$LOCK_FILE"
echo "[Setup] Initialization complete."

# Stop PostgreSQL.
echo "[Setup] Stopping temporary PostgreSQL instance..."
pg_ctl -D "$PGDATA" -m fast -w stop

# Start PostgreSQL in foreground.
echo "[Setup] Starting PostgreSQL in foreground..."
exec postgres