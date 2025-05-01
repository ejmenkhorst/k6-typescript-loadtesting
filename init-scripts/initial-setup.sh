#!/bin/bash
# initial-setup.sh - Script to initialize CouchDB setup
set -e  # Exit immediately if a command exits with a non-zero status
set -u  # Treat unset variables as an error
set -o pipefail  # Catch errors in piped commands
#set -x  # Enable debug mode for troubleshooting

# Source the replication and helper functions
source ./helpers.sh
source ./replicate.sh

# Load environment variables from the mounted .env file
ENV_FILE="/app/.env"
if [ -f "$ENV_FILE" ]; then
  source "$ENV_FILE"
else
  echo ".env file not found at: $ENV_FILE!"
  exit 1
fi

# Log the start of the script
echo "Starting initial setup script..."

# Main setup process
main() {
  # Check if all CouchDB instances are ready
   wait_for_all_dbs

  # Set up the _users databases
  setup_users_databases

  # Create the new car database
  echo "Creating the car database..."
  create_database

  # Insert test documents into couchdb-master
  echo "Inserting test documents into the car database..."
  insert_documents

  # Wait for all CouchDB services to be up
  wait_for_all_dbs

  # Start replication configuration setup if all databases are ready
  if [ $? -eq 0 ]; then
    echo "All CouchDB databases are ready. Starting replication configuration setup via function: setup_replication..."
    setup_replication
  else
    echo "One or more CouchDB databases failed to initialize. Replication configuration setup not started."
    exit 1
  fi

  echo "Initialization and replication setup is completed successfully."
}

# Execute the main function
main