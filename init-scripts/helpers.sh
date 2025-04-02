#!/bin/bash
# helpers.sh - Contains helper functions for CouchDB setup
set -x  # Enable debug mode

# Source the configuration file
source ./config.sh

# Function to check if CouchDB is ready
#check_couchdb_ready() {
#  response=$(curl -s -u "$COUCHDB_USER:$COUCHDB_PASSWORD" --max-time 30 "http://$COUCHDB_HOST:$COUCHDB_PORT/_up")
#  echo "$response" | grep -q '"status":"ok"'
#}

# Function to check if CouchDB is ready
check_couchdb_ready() {
  response=$(curl -X GET -u "$COUCHDB_USER":"$COUCHDB_PASSWORD" "http://$COUCHDB_HOST:$COUCHDB_PORT/_up")
  echo "$response" | grep -q '"status":"ok"'
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

# Function to create a new cars database
create_database() {
  response=$(curl -s -o /dev/null -w "%{http_code}" -u "$COUCHDB_USER":"$COUCHDB_PASSWORD" -X PUT "http://$COUCHDB_HOST:$COUCHDB_PORT/$COUCHDB_DB_NAME")
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
  response=$(curl -s -o /dev/null -w "%{http_code}" -u "$COUCHDB_USER:$COUCHDB_PASSWORD" -X POST "http://$COUCHDB_HOST:$COUCHDB_PORT/$COUCHDB_DB_NAME/_bulk_docs" \
    -H "Content-Type: application/json" \
    -d "$json_data")

  if [ "$response" -eq 201 ]; then
    echo "Documents added successfully to database '$COUCHDB_DB_NAME'."
  else
    echo "Failed to add documents to database '$COUCHDB_DB_NAME'. HTTP status code: $response"
  fi
}

echo 'Bulk insert complete.'