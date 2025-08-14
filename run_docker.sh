#!/bin/bash

# NOTE: use "chmod +x run_docker.sh" to make this file executable

set -e  # Exit immediately if a command exits with a non-zero status
set -u  # Treat unset variables as an error when substituting

# Resolve script directory and load .env from there
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
if [ -f "$SCRIPT_DIR/.env" ]; then
  source "$SCRIPT_DIR/.env"
else
  echo ".env file not found in $SCRIPT_DIR. Exiting..."
  exit 1
fi

# Generate servers.json dynamically for pgAdmin
mkdir -p "$SCRIPT_DIR/pgadmin"

cat > "$SCRIPT_DIR/pgadmin/servers.json" <<EOF
{
  "Servers": {
    "1": {
      "Name": "PostgreSQL",
      "Group": "Servers",
      "Host": "postgres",
      "Port": 5432,
      "MaintenanceDB": "postgres",
      "Username": "${POSTGRES_USER}",
      "SSLMode": "prefer"
    }
  }
}
EOF

echo "Generated pgadmin/servers.json file."

# Stop and remove old Docker containers
echo "Stopping and removing old Docker containers..."
docker-compose rm -fs

# Build and start Docker containers
echo "Building and starting Docker containers..."
docker-compose up --build -d

# Wait for the containers to start up
echo "Waiting for containers to start up..."
sleep 5

# Ensure default database exists
echo "Checking if database ${POSTGRES_DB} exists..."
DB_EXISTS=$(docker exec -i postgres psql -U "${POSTGRES_USER}" -d postgres \
  -tAc "SELECT 1 FROM pg_database WHERE datname='${POSTGRES_DB}';")

if [ "$DB_EXISTS" != "1" ]; then
  echo "Database ${POSTGRES_DB} does not exist. Creating..."
  docker exec -i postgres createdb -U "${POSTGRES_USER}" "${POSTGRES_DB}"
else
  echo "Database ${POSTGRES_DB} already exists."
fi

# Enable pgvector extension in the default DB
echo "Enabling pgvector extension in ${POSTGRES_DB}..."
docker exec -i postgres psql -U "${POSTGRES_USER}" -d "${POSTGRES_DB}" \
  -c "CREATE EXTENSION IF NOT EXISTS vector;"

# Create and initialize any extra DBs from sql/*.sql
if [ -d "$SCRIPT_DIR/sql" ] && [ "$(ls -A "$SCRIPT_DIR"/sql/*.sql 2>/dev/null)" ]; then
  echo "Creating databases from SQL files..."
  for file in "$SCRIPT_DIR"/sql/*.sql; do
    db_name=$(basename "$file" .sql)

    # Create DB if missing
    DB_EXISTS=$(docker exec -i postgres psql -U "${POSTGRES_USER}" -d postgres \
      -tAc "SELECT 1 FROM pg_database WHERE datname='${db_name}';")
    if [ "$DB_EXISTS" != "1" ]; then
      echo "Creating database: $db_name"
      docker exec -i postgres createdb -U "$POSTGRES_USER" "$db_name"
    fi

    # Load schema/data
    echo "Loading $file into $db_name..."
    docker exec -i postgres psql -U "$POSTGRES_USER" -d "$db_name" < "$file"

    # Enable pgvector in the DB
    echo "Enabling pgvector extension in $db_name..."
    docker exec -i postgres psql -U "$POSTGRES_USER" -d "$db_name" \
      -c "CREATE EXTENSION IF NOT EXISTS vector;"
  done
else
  echo "No SQL files found in ./sql — skipping additional database creation."
fi

echo "Initialization complete! pgvector is ready in all databases."
