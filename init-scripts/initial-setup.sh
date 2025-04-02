#!/bin/bash
# initial-setup.sh
set -x  # Enable debug mode

# Source the configuration and helper functions shell script
source ./config.sh
source helpers.sh

shift 2

# Log the start of the script
echo "Starting initial setup script..."

# Wait for CouchDB to be ready with a maximum of 3 attempts and 10 seconds interval
echo "Waiting for CouchDB at $COUCHDB_HOST:$COUCHDB_PORT to be ready..."
attempt=1
max_attempts=3
while [ $attempt -le $max_attempts ]; do
  if check_couchdb_ready; then
    echo "CouchDB is ready at $COUCHDB_HOST:$COUCHDB_PORT!"
    break
  fi
  if [ $attempt -eq $max_attempts ]; then
    echo "CouchDB did not become ready after $max_attempts attempts. Exiting script."
    exit 1  # Exit the script with a non-zero status code
  fi
  echo "CouchDB is not ready yet, waiting..."
  sleep 10
  ((attempt++))
done

# Check if _users database exists, if not, create it
echo "Checking if _users database exists..."
if [ "$(check_users_db)" -ne 200 ]; then
  echo "_users database does not exist, creating it..."
  create_users_db
  echo "_users database created successfully."
else
  echo "_users database already exists."
fi

# Create the new database
create_database

# Insert test documents
insert_documents

echo 'Initialisation setup completed.'