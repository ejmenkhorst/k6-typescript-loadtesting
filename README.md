# k6-typescript-loadtesting

Portfolio project Grafana K6 load testing with TypeScript.

## project setup

This project is using several docker-containers to setup this project.
It integrates Prometheus exporters with CouchDB instances, providing a clean and scalable monitoring solution.

**prometheus exporters**  
Benefits of This Approach:

1. **Separation of Concerns**:

   - The Prometheus exporters handle metrics conversion, keeping CouchDB instances lightweight.

2. **Scalability**:

   - Each CouchDB instance has its own exporter, making it easier to scale and monitor multiple instances.

3. **Standardized Metrics**:

   - The exporters provide a consistent Prometheus-compatible metrics format.

4. **Security**:
   - Prometheus does not need direct access to CouchDB credentials; it only communicates with the exporters.

### Access the services:

#### CouchDB Web Interface

- Access the CouchDB web interface [couchdb-master](http://localhost:5984/_utils/#login).
- Access the CouchDB web interface [car1](http://localhost:5985/_utils/#login).
- Access the CouchDB web interface [car2](http://localhost:5986/_utils/#login).

#### Prometheus UI

The Prometheus configuration is managed by [prometheus.yml](./prometheus/prometheus.yml) and this makes sure that the prometheus-exporters are setup correctly by default.

- Access Prometheus at http://localhost:9090.

#### Grafana UI

Grafana dashboards are for now configured for each specific database instance and can be found in the [dashboards folder](./grafana/provisioning/dashboards/)  
The datasource configuration to prometheus can be found in the [datasources.yml](./grafana/provisioning/datasources/datasources.yml)

- Access Grafana at http://localhost:3000 (default username: admin, password: admin).

### folder structure

- config folder: contains ini configuration files for couch-db instances
- db folder: contains the database data -> remember to empty it manually if you want to start from scratch
- init-scripts folder: contains the bash shell scripts to setup all the databases and replication settings
- grafana folder: contains the dashboards and datasources as code for a consistent experience
- prometheus folder: contains the configuration settings

### setup Guide

1. **Build Docker Image For Executing Shell Scripts:**

   ```bash
   docker build -t couchdb-bash-setup-image .

   ```

2. **Initialise all containers**

   ```bash
   docker-compose up --build -d
   ```

### init-scripts

The init-scripts folder is used by the init_couchdb container to setup the whole database setup including testdata and replication between instances.  
The following paragraphs describe concise each scripts functions.

#### initial-setup.sh functions

1. **`wait_for_all_dbs`**: Ensures all CouchDB instances (master, car1, car2) are ready by calling wait_for_db for each instance.

2. **`setup_users_databases`**: Sets up the \_users database on all CouchDB instances, creating it if it doesn't already exist.

3. **`create_database`**: Creates the main cars database on the CouchDB master instance.

4. **`insert_documents`**: Inserts test documents into the cars database on the CouchDB master instance.

5. **`start_replication_setup`**: Configures bidirectional replication between the master and car1/car2 databases.

6. **`main`**: Orchestrates the setup process by calling the above functions in sequence to initialize and configure the CouchDB environment.

#### helpers.sh - functions

1. **`wait_for_all_dbs`**: Ensures all CouchDB instances (master, car1, car2) are ready by calling `wait_for_db` for each instance.

2. **`wait_for_db`**: Waits for a specific CouchDB instance to become available by checking its `_up` endpoint with retries.

3. **`setup_users_databases`**: Sets up the `_users` database on all CouchDB instances, creating it if it doesn't exist.

4. **`check_and_create_users_db`**: Checks if the `_users` database exists on a specific CouchDB instance and creates it if necessary.

5. **`create_database`**: Creates the main `cars` database on the CouchDB master instance, handling cases where it already exists.

6. **`insert_documents`**: Inserts a batch of test documents into the `cars` database on the CouchDB master instance using the `_bulk_docs` endpoint.

#### replicate.sh - functions

1. **`add_replication_to_replicator`**: Adds a replication job to the `_replicator` database, specifying the source, target, and whether the replication is continuous.

2. **`start_replication_setup`**: Ensures the `_replicator` database exists on the CouchDB master instance and sets up bidirectional replication between the master and car1/car2 databases.

## Running K6 tests

Invoke watch mode before making changes to test files

### Enter watch mode when changing implementation of tests

```bash
npm run watch
```

### Execute testcases specified in [package.json](./package.json)

```bash
npm run test:car1
npm run test:car2
```
