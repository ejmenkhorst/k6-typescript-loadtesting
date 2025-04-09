#!/bin/bash
# helpers.sh - Contains helper functions for CouchDB setup
set -e  # Exit immediately if a command exits with a non-zero status
set -u  # Treat unset variables as an error
set -o pipefail  # Catch errors in piped commands

# Load environment variables from the mounted .env file
ENV_FILE="/app/.env"
if [ -f "$ENV_FILE" ]; then
  source "$ENV_FILE"
else
  echo ".env file not found at: $ENV_FILE!"
  exit 1
fi

# Function to wait for all CouchDB instances to be ready
wait_for_all_dbs() {
  echo "Waiting for all CouchDB instances to be ready..."
  wait_for_db "http://$DB_USER:$DB_PASSWORD_MASTER@$DB_MASTER"
  wait_for_db "http://$DB_USER:$DB_PASSWORD_CAR1@$DB_CAR1"
  wait_for_db "http://$DB_USER:$DB_PASSWORD_CAR2@$DB_CAR2"
}

# Function to wait until CouchDB is up and running
wait_for_db() {
  local db_url=$1
  local retries=30
  local count=0

  echo "Waiting for CouchDB at $db_url to be ready..."

  while [ $count -lt $retries ]; do
    # Try to reach the database's HTTP API
    http_response=$(curl --write-out "%{http_code}" --silent --output /dev/null "$db_url/_up")

    if [ "$http_response" -eq 200 ]; then
      echo "CouchDB at $db_url is up and running!"
      return 0
    fi

    count=$((count + 1))
    echo "Waiting... ($count/$retries)"
    sleep 5
  done

  echo "CouchDB at $db_url did not respond in time!"
  return 1
}

# Function to set up the _users database for all CouchDB instances
setup_users_databases() {
  echo "Setting up _users databases for all CouchDB instances..."
  check_and_create_users_db "$DB_MASTER" "$DB_USER" "$DB_PASSWORD_MASTER"
  check_and_create_users_db "$DB_CAR1" "$DB_USER" "$DB_PASSWORD_CAR1"
  check_and_create_users_db "$DB_CAR2" "$DB_USER" "$DB_PASSWORD_CAR2"
}

# Function to check and create the _users database
check_and_create_users_db() {
  local db_host=$1
  local db_user=$2
  local db_password=$3

  # Check the HTTP status code of the _users database endpoint
  http_code=$(curl -u "$db_user:$db_password" -s -o /dev/null -w "%{http_code}" "http://$db_host/_users")

  if [ "$http_code" -eq 404 ]; then
    echo "_users database not found on $db_host Creating _users..."
    curl -u "$db_user:$db_password" -X PUT "http://$db_host/_users"
    echo "_users database created on $db_host."
  elif [ "$http_code" -eq 200 ]; then
    echo "_users database already exists on $db_host."
  else
    echo "Error checking _users database on $db_host HTTP code: $http_code"
    return 1
  fi
}

# Function to create a new database
create_database() {
  local response
  response=$(curl -s -o /dev/null -w "%{http_code}" -u "$DB_USER:$DB_PASSWORD_MASTER" -X PUT "http://$DB_MASTER/$NEW_DB_NAME")

  case "$response" in
    201)
      echo "Database '$NEW_DB_NAME' created successfully."
      ;;
    412)
      echo "Database '$NEW_DB_NAME' already exists."
      ;;
    *)
      echo "Failed to create database '$NEW_DB_NAME'. HTTP status code: $response"
      return 1
      ;;
  esac
}

# Function to insert multiple documents
insert_documents() {
  local json_data='{"docs":['
  for i in {1..5}; do
    json_data+='{"_id": "doc_'$i'", "car_name": "Car '$i'", "latitude": "134.75'$i'"},'
  done
  json_data="${json_data%,}]}"  # Remove trailing comma and close JSON array

  local response
  response=$(curl -s -o /dev/null -w "%{http_code}" -u "$DB_USER:$DB_PASSWORD_MASTER" -X POST "http://$DB_MASTER/$NEW_DB_NAME/_bulk_docs" \
    -H "Content-Type: application/json" \
    -d "$json_data")

  if [ "$response" -eq 201 ]; then
    echo "Car bulk documents added successfully to database '$NEW_DB_NAME'."
  else
    echo "Failed to add documents to database '$NEW_DB_NAME'. HTTP status code: $response"
    return 1
  fi
}

