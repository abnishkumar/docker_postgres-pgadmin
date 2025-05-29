#!/bin/bash

# NOTE: use "chmod +x run_docker.sh" to make this file executable

set -e # Exit immediately if a command exits with a non zero status
set -u # Treat unset variables as an error when substituting

# Source the .env file to load environment variables
if [ -f .env ]; then
  source .env
fi

# Generate servers.json dynamically
mkdir -p pgadmin

cat > pgadmin/servers.json <<EOF
{
  "Servers": {
    "1": {
      "Name": "PostgreSQL",
      "Group": "Servers",
      "Host": "postgres",
      "Port": 5432,
      "MaintenanceDB": "postgres",
      "Username": "$POSTGRES_USER",
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

# # Create databases
echo "Creating databases..."

# Loop over each SQL file in the sql directory
for file in sql/*.sql; do
    # Extract the name of the file without the extension
    db_name=$(basename "$file" .sql)

    # Create the database with the extracted name
    docker exec -i postgres createdb -U "$POSTGRES_USER" "$db_name"

    # Load the SQL dump file into the new database
    docker exec -i postgres psql -U "$POSTGRES_USER" -d "$db_name" < "$file"
done

echo "Initialization complete!"