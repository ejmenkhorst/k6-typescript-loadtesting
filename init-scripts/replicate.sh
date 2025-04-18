#!/bin/bash

# Wait for CouchDB to start
sleep 10

# Function to add replication job to _replicator manually
add_replication_to_replicator() {
  local source=$1
  local target=$2
  local continuous=$3

  curl -X POST "http://$DB_USER:$DB_PASSWORD_MASTER@$DB_MASTER/_replicator" \
    -H "Content-Type: application/json" \
    -d "{
      \"source\": \"$source\",
      \"target\": \"$target\",
      \"continuous\": $continuous,
      \"create_target\": true
    }"
}

# Function to set up continuous replication between the databases
start_replication_setup() {
  # Create _replicatorDB for couchdb-master if this does not exist
  if ! curl -u "$DB_USER:$DB_PASSWORD_MASTER" -s -o /dev/null -w "%{http_code}" "http://$DB_MASTER/_replicator" | grep -q "200"; then
    echo "_replicator database does not exist. Creating _replicator database..."
    curl -u "$DB_USER:$DB_PASSWORD_MASTER" -X PUT "http://$DB_MASTER/_replicator"
    echo "_replicator database created."
  else
    echo "_replicator database already exists."
  fi

  # Add replication job from cars to cars on couchdb-car1
  add_replication_to_replicator "http://$DB_USER:$DB_PASSWORD_MASTER@$DB_MASTER/$NEW_DB_NAME" \
                                "http://$DB_USER:$DB_PASSWORD_CAR1@$DB_CAR1/$NEW_DB_NAME" true

  # Add replication job from cars to cars on couchdb-car2
  add_replication_to_replicator "http://$DB_USER:$DB_PASSWORD_MASTER@$DB_MASTER/$NEW_DB_NAME" \
                                "http://$DB_USER:$DB_PASSWORD_CAR2@$DB_CAR2/$NEW_DB_NAME" true

  # Add replication job from cars on car1 to cars on couchdb-master (bidirectional replication)
  add_replication_to_replicator "http://$DB_USER:$DB_PASSWORD_CAR1@$DB_CAR1/$NEW_DB_NAME" \
                                "http://$DB_USER:$DB_PASSWORD_MASTER@$DB_MASTER/$NEW_DB_NAME" true

  # Add replication job from cars on car2 to cars on couchdb-master (bidirectional replication)
  add_replication_to_replicator "http://$DB_USER:$DB_PASSWORD_CAR2@$DB_CAR2/$NEW_DB_NAME" \
                                "http://$DB_USER:$DB_PASSWORD_MASTER@$DB_MASTER/$NEW_DB_NAME" true
}
