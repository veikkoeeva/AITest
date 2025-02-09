#!/bin/bash
set -e

echo "[Setup] Starting custom PostgreSQL initialization..."

PGDATA="/var/lib/postgresql/data"
LOCK_FILE="$PGDATA/.init_done"

# The container already runs as 'postgres'
# (thanks to the Dockerfile's "USER postgres"), so we can run commands directly.

# Check if initialization has been done already.
if [ -f "$LOCK_FILE" ]; then
  echo "[Setup] Initialization already completed. Reloading config..."
  pg_ctl reload -D "$PGDATA"
  exec postgres
fi

# If the data directory is empty, initialize the database
if [ ! -s "$PGDATA/PG_VERSION" ]; then
    echo "[Setup] Initializing database..."
    initdb --username=postgres
fi

# Start PostgreSQL in the background so that we can modify config files.
echo "[Setup] Starting PostgreSQL temporarily..."
pg_ctl -D "$PGDATA" -o "-c listen_addresses='*'" -w start

# Backup and update pg_hba.conf for trusted local connections
if [ -f "$PGDATA/pg_hba.conf" ]; then
    echo "[Setup] Backing up and updating pg_hba.conf..."
    cp "$PGDATA/pg_hba.conf" "${PGDATA}/pg_hba.conf.backup"
    
    cat > "$PGDATA/pg_hba.conf" <<'EOL'
# Trust authentication for local connections only
# Allow local Unix socket connections
local   all   all   trust

# Allow connections from localhost and the Docker gateway IP
host    all   all   172.17.0.1/32  trust
host    all   all   ::1/128        trust

# Deny everything else
host    all   all   0.0.0.0/0      reject
EOL

    echo "[Setup] pg_hba.conf updated."
    echo "[Setup] Updated pg_hba.conf contents:"
    cat "$PGDATA/pg_hba.conf"
else
    echo "[ERROR] pg_hba.conf not found. Aborting initialization."
    exit 1
fi

# Reload PostgreSQL configuration to apply changes
echo "[Setup] Reloading PostgreSQL configuration..."
pg_ctl reload -D "$PGDATA"

until pg_isready --username=postgres --host=localhost; do
    sleep 2
done

echo "[Setup] Running database initialization..."
/create-dev-db-and-extensions.sh

# Mark initialization as done
touch "$LOCK_FILE"
echo "[Setup] Initialization complete; PostgreSQL configured for trust authentication."

# Stop the temporary PostgreSQL server
pg_ctl -D "$PGDATA" -m fast -w stop

# Finally, start PostgreSQL in the foreground
exec postgres
