#!/bin/bash
# initial-setup.sh
set -x  # Enable debug mode

# Source the configuration and helper functions shell script
source ./config.sh
source ./helpers.sh
source ./replicate.sh

shift 2

# Log the start of the script
echo "Starting initial setup script..."

# Wait for CouchDB to be ready with a maximum of 3 attempts and 10 seconds interval
#echo "Waiting for CouchDB at $COUCHDB_HOST:$COUCHDB_PORT to be ready..."
#attempt=1
#max_attempts=3
#while [ $attempt -le $max_attempts ]; do
#  if check_couchdb_ready; then
#    echo "CouchDB is ready at $COUCHDB_HOST:$COUCHDB_PORT!"
#    break
#  fi
#  if [ $attempt -eq $max_attempts ]; then
#    echo "CouchDB did not become ready after $max_attempts attempts. Exiting script."
#    exit 1  # Exit the script with a non-zero status code
#  fi
#  echo "CouchDB is not ready yet, waiting..."
#  sleep 10
#  ((attempt++))
#done

# Check if all couchDB's are up and running before setting them up
check_all_couchdb_ready

# Check and create _users database for couchdb-master car1 and car2
check_and_create_users_db "couchdb-master" "5984" "admin" "A24cvmri"
check_and_create_users_db "couchdb-car1" "5984" "admin" "9VQhWrfW"
check_and_create_users_db "couchdb-car2" "5984" "admin" "ouPFQ6mj"

# Create the new car database
create_database

# Insert test documents into couchdb-master
insert_documents

# Wait for all CouchDB services to be up
wait_for_db "http://admin:A24cvmri@couchdb-master:5984" && \
wait_for_db "http://admin:9VQhWrfW@couchdb-car1:5984" && \
wait_for_db "http://admin:ouPFQ6mj@couchdb-car2:5984"

# If all databases are up, start replication
if [ $? -eq 0 ]; then
  echo "All CouchDB databases are ready. Starting replication..."
  start_replication_setup
else
  echo "One or more CouchDB databases failed to initialize. Replication not started."
  exit 1
fi

echo 'Initialisation setup completed.'