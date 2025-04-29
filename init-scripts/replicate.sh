#!/bin/bash

# Exit immediately if a variable is unset
set -u

# Load environment variables from the mounted .env file
ENV_FILE="/app/.env"
if [ -f "$ENV_FILE" ]; then
  source "$ENV_FILE"
else
  echo ".env file not found at: $ENV_FILE!"
  exit 1
fi

# Wait for CouchDB to start
sleep 10

# Function to add replication job to the local _replicator database
add_replication_to_local_replicator() {
  local db_user=$1
  local db_password=$2
  local db_host=$3
  local source=$4
  local target=$5
  local continuous=$6

  # Validate arguments
  if [[ -z "$db_user" || -z "$db_password" || -z "$db_host" || -z "$source" || -z "$target" || -z "$continuous" ]]; then
    echo "Error: Missing arguments in add_replication_to_local_replicator."
    exit 1
  fi

  curl -X POST "http://$db_user:$db_password@$db_host/_replicator" \
    -H "Content-Type: application/json" \
    -d "{
      \"source\": \"$source\",
      \"target\": \"$target\",
      \"continuous\": $continuous,
      \"create_target\": true
    }"
}

# Function to set up replication on each instance
setup_replication_on_instance() {
  local db_user=$1
  local db_password=$2
  local db_host=$3

  # Validate arguments
  if [[ -z "$db_user" || -z "$db_password" || -z "$db_host" ]]; then
    echo "Error: Missing arguments in setup_replication_on_instance."
    exit 1
  fi

  # Create _replicator database if it doesn't exist
  if ! curl -u "$db_user:$db_password" -s -o /dev/null -w "%{http_code}" "http://$db_host/_replicator" | grep -q "200"; then
    echo "_replicator database does not exist on $db_host. Creating _replicator database..."
    curl -u "$db_user:$db_password" -X PUT "http://$db_host/_replicator"
    echo "_replicator database created on $db_host."
  else
    echo "_replicator database already exists on $db_host."
  fi
}

# Function to set up replication for all instances
setup_replication() {
  # Ensure required environment variables are set
  if [[ -z "$DB_USER" || -z "$DB_PASSWORD_MASTER" || -z "$DB_PASSWORD_CAR1" || -z "$DB_PASSWORD_CAR2" || -z "$DB_MASTER" || -z "$DB_CAR1" || -z "$DB_CAR2" || -z "$NEW_DB_NAME" ]]; then
    echo "Error: One or more required environment variables are not set in the .env file."
    exit 1
  fi

  # Set up replication on couchdb-master
  echo "Setting up replication on couchdb-master..."
  setup_replication_on_instance "$DB_USER" "$DB_PASSWORD_MASTER" "$DB_MASTER"
  add_replication_to_local_replicator "$DB_USER" "$DB_PASSWORD_MASTER" "$DB_MASTER" \
    "http://$DB_USER:$DB_PASSWORD_MASTER@$DB_MASTER/$NEW_DB_NAME" \
    "http://$DB_USER:$DB_PASSWORD_CAR1@$DB_CAR1/$NEW_DB_NAME" true
  add_replication_to_local_replicator "$DB_USER" "$DB_PASSWORD_MASTER" "$DB_MASTER" \
    "http://$DB_USER:$DB_PASSWORD_MASTER@$DB_MASTER/$NEW_DB_NAME" \
    "http://$DB_USER:$DB_PASSWORD_CAR2@$DB_CAR2/$NEW_DB_NAME" true

  # Set up replication on couchdb-car1
  echo "Setting up replication on couchdb-car1..."
  setup_replication_on_instance "$DB_USER" "$DB_PASSWORD_CAR1" "$DB_CAR1"
  add_replication_to_local_replicator "$DB_USER" "$DB_PASSWORD_CAR1" "$DB_CAR1" \
    "http://$DB_USER:$DB_PASSWORD_CAR1@$DB_CAR1/$NEW_DB_NAME" \
    "http://$DB_USER:$DB_PASSWORD_MASTER@$DB_MASTER/$NEW_DB_NAME" true

  # Set up replication on couchdb-car2
  echo "Setting up replication on couchdb-car2..."
  setup_replication_on_instance "$DB_USER" "$DB_PASSWORD_CAR2" "$DB_CAR2"
  add_replication_to_local_replicator "$DB_USER" "$DB_PASSWORD_CAR2" "$DB_CAR2" \
    "http://$DB_USER:$DB_PASSWORD_CAR2@$DB_CAR2/$NEW_DB_NAME" \
    "http://$DB_USER:$DB_PASSWORD_MASTER@$DB_MASTER/$NEW_DB_NAME" true
}
