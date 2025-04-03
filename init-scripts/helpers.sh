#!/bin/bash
# helpers.sh - Contains helper functions for CouchDB setup
set -x  # Enable debug mode

# Source the configuration file
source ./config.sh

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



# Wait for all CouchDB instances to be ready with a maximum of 3 attempts and 10 seconds interval
check_all_couchdb_ready() {
  local attempt=1
  local max_attempts=3

  echo "Waiting for CouchDB instances to be ready..."

  while [ $attempt -le $max_attempts ]; do
    all_ready=true

    # Check each CouchDB instance
    for db_host in "$DB_HOST_MASTER" "$DB_HOST_CAR1" "$DB_HOST_CAR2"; do
      if [ "$db_host" == "$DB_HOST_MASTER" ]; then
        db_port=$DB_PORT_MASTER
        db_password=$DB_PASSWORD_MASTER
      elif [ "$db_host" == "$DB_HOST_CAR1" ]; then
        db_port=$DB_PORT_CAR1
        db_password=$DB_PASSWORD_CAR1
      elif [ "$db_host" == "$DB_HOST_CAR2" ]; then
        db_port=$DB_PORT_CAR2
        db_password=$DB_PASSWORD_CAR2
      fi

      if ! check_couchdb_ready "$db_host" "$db_port" "$DB_USER" "$db_password"; then
        echo "CouchDB at $db_host:$db_port is not ready yet."
        all_ready=false
        break
      fi
    done

    # If all databases are ready, exit the loop
    if [ "$all_ready" = true ]; then
      echo "All CouchDB instances are ready!"
      break
    fi

    # Retry or exit if max attempts are reached
    if [ $attempt -eq $max_attempts ]; then
      echo "CouchDB instances did not become ready after $max_attempts attempts. Exiting script."
      exit 1  # Exit the script with a non-zero status code
    fi

    echo "Not all CouchDB instances are ready yet, waiting..."
    sleep 10
    ((attempt++))
  done
}

# Function to check if a CouchDB instance is ready using curl
check_couchdb_ready() {
  local db_host=$1
  local db_port=$2
  local db_user=$3
  local db_password=$4

  # Perform a curl request to check if the CouchDB instance is up and running
  curl -s -u "$db_user:$db_password" http://"$db_host":"$db_port"/_up | grep -q '"ok"'
}

# Function to check if the _users database exists
check_users_db() {
  curl -s -o /dev/null -w "%{http_code}" -u "$COUCHDB_USER":"$COUCHDB_PASSWORD" "http://$COUCHDB_HOST:$COUCHDB_PORT/_users"
}

# Function to create the _users database if it does not exist
create_users_db() {
  echo "Creating the _users database..."
  curl -X PUT -u "$COUCHDB_USER":"$COUCHDB_PASSWORD" "http://$COUCHDB_HOST:$COUCHDB_PORT/_users"
}

# Function to check and create _users database if not exists
check_and_create_users_db() {
  local db_host=$1
  local db_port=$2
  local db_user=$3
  local db_password=$4

  # Check the HTTP status code of the _users database endpoint
  http_code=$(curl -u "$db_user:$db_password" -s -o /dev/null -w "%{http_code}" "http://$db_host:$db_port/_users")

  if [ "$http_code" -eq 404 ]; then
    # _users database does not exist, so create it
    echo "_users database not found on $db_host:$db_port. Creating _users..."
    curl -u "$db_user:$db_password" -X PUT "http://$db_host:$db_port/_users"
    echo "_users database created on $db_host:$db_port."
  elif [ "$http_code" -eq 200 ]; then
    # _users database exists
    echo "_users database already exists on $db_host:$db_port."
  else
    # Handle other HTTP errors (e.g., 401 Unauthorized, 500 Internal Server Error)
    echo "Error checking _users database on $db_host:$db_port. HTTP code: $http_code"
  fi
}

# Function to create a new cars database
create_database() {
  response=$(curl -s -o /dev/null -w "%{http_code}" -u "$DB_USER":"$DB_PASSWORD_MASTER" -X PUT "http://$DB_HOST_MASTER:$DB_PORT_MASTER/$COUCHDB_DB_NAME")
  if [ "$response" -eq 201 ]; then
    echo "Database '$COUCHDB_DB_NAME' created successfully."
  elif [ "$response" -eq 412 ]; then
    echo "Database '$COUCHDB_DB_NAME' already exists."
  else
    echo "Failed to create database '$COUCHDB_DB_NAME'. HTTP status code: $response"
  fi
}

# Function to insert multiple documents
insert_documents() {
  # Construct the JSON payload
  json_data='{"docs":['
  for i in {1..5}; do
        json_data+='{"_id": "doc_'$i'", "car name": "Car '$i'", "latitude": "134.75'$i'"},'
  done
  # Remove the trailing comma and close the JSON array
  json_data="${json_data%,}]}"

  # Send the bulk insert request
  response=$(curl -s -o /dev/null -w "%{http_code}" -u "$DB_USER:$DB_PASSWORD_MASTER" -X POST "http://$DB_HOST_MASTER:$DB_PORT_MASTER/$COUCHDB_DB_NAME/_bulk_docs" \
    -H "Content-Type: application/json" \
    -d "$json_data")

  if [ "$response" -eq 201 ]; then
    echo "Documents added successfully to database '$COUCHDB_DB_NAME'."
  else
    echo "Failed to add documents to database '$COUCHDB_DB_NAME'. HTTP status code: $response"
  fi
}

echo 'Bulk insert complete.'