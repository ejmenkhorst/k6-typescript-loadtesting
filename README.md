# k6-typescript-loadtesting

Portfolio project Grafana K6 load testing with TypeScript.

## Table of Contents

1. [Project Setup](#project-setup)
   - [Prometheus Exporters](#prometheus-exporters)
   - [Access the Services](#access-the-services)
     - [CouchDB Web Interface](#couchdb-web-interface)
     - [Prometheus UI](#prometheus-ui)
     - [Grafana UI](#grafana-ui)
   - [Folder Structure](#folder-structure)
   - [Setup Guide](#setup-guide)
2. [Init Scripts](#init-scripts)
   - [initial-setup.sh Functions](#initial-setupsh-functions)
   - [helpers.sh Functions](#helperssh-functions)
   - [replicate.sh Functions](#replicatesh-functions)
3. [Running K6 Tests](#running-k6-tests)
   - [Enter Watch Mode](#enter-watch-mode-when-changing-implementation-of-tests)
   - [Execute Testcases](#execute-testcases-specified-in-packagejson)
     - [Preparation Steps](#preparation-steps-before-executing-a-load-test)
     - [Tweak the Load Test](#tweak-the-load-test)
     - [Transpile the Load Test](#transpile-the-loadtest)
     - [Run Testcases](#run-testcases-for-the-different-database-instances)

---

## Project Setup

This project is using several docker-containers to setup this project.
It integrates Prometheus exporters with CouchDB instances, providing a clean and scalable monitoring solution.

### Prometheus Exporters

Prometheus exporters provide standardized metrics, scalability, and secure monitoring without direct CouchDB access, ensuring lightweight performance.

Benefits of this approach:

1. **Separation of Concerns**:

   - The Prometheus exporters handle metrics conversion, keeping CouchDB instances lightweight.

2. **Scalability**:

   - Each CouchDB instance has its own exporter, making it easier to scale and monitor multiple instances.

3. **Standardized Metrics**:

   - The exporters provide a consistent Prometheus-compatible metrics format.

4. **Security**:
   - Prometheus does not need direct access to CouchDB credentials; it only communicates with the exporters.

### Access the Services

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

### Folder Structure

- config folder: contains ini configuration files for couch-db instances
- db folder: contains the database data -> remember to empty it manually if you want to start from scratch
- init-scripts folder: contains the bash shell scripts to setup all the databases and replication settings
- grafana folder: contains the dashboards and datasources as code for a consistent experience
- prometheus folder: contains the configuration settings

### Setup Guide

1. **Build Docker Image For Executing Shell Scripts:**

   ```bash
   docker build -t couchdb-bash-setup-image .
   ```

2. **Initialise all containers**

   ```bash
   docker-compose up --build -d
   ```

## Init Scripts

The init-scripts folder is used by the init_couchdb container to setup the whole database setup including testdata and replication between instances.  
The following paragraphs describe concise each scripts functions.

### initial-setup.sh Functions

1. **`wait_for_all_dbs`**: Ensures all CouchDB instances (master, car1, car2) are ready by calling wait_for_db for each instance.

2. **`setup_users_databases`**: Sets up the \_users database on all CouchDB instances, creating it if it doesn't already exist.

3. **`create_database`**: Creates the main cars database on the CouchDB master instance.

4. **`insert_documents`**: Inserts test documents into the cars database on the CouchDB master instance.

5. **`start_replication_setup`**: Configures bidirectional replication between the master and car1/car2 databases.

6. **`main`**: Orchestrates the setup process by calling the above functions in sequence to initialize and configure the CouchDB environment.

### helpers.sh Functions

1. **`wait_for_all_dbs`**: Ensures all CouchDB instances (master, car1, car2) are ready by calling `wait_for_db` for each instance.

2. **`wait_for_db`**: Waits for a specific CouchDB instance to become available by checking its `_up` endpoint with retries.

3. **`setup_users_databases`**: Sets up the `_users` database on all CouchDB instances, creating it if it doesn't exist.

4. **`check_and_create_users_db`**: Checks if the `_users` database exists on a specific CouchDB instance and creates it if necessary.

5. **`create_database`**: Creates the main `cars` database on the CouchDB master instance, handling cases where it already exists.

6. **`insert_documents`**: Inserts a batch of test documents into the `cars` database on the CouchDB master instance using the `_bulk_docs` endpoint.

### replicate.sh Functions

1. **`add_replication_to_local_replicator`**: Adds a replication job to the `_replicator` database of a specific CouchDB instance.

2. **`setup_replication_on_instance`**: Ensures the `_replicator` database exists on a specific CouchDB instance.

3. **`setup_replication_instance`**: Ensures the `_replicator` database exists on the CouchDB master instance and sets up bidirectional replication between the master and car1/car2 databases.

   - Master: Replicates the cars database to couchdb-car1 and couchdb-car2
   - Car1: Replicates the the cars database back to couchdb-master
   - Car2: Replicates the the cars database back to couchdb-master

## Running K6 Tests

Invoke watch mode before making changes to test files - this will automatically transpile the files to the **_dist_** folder.

### Enter Watch Mode When Changing Implementation of Tests

```bash
npm run watch
```

### Execute Testcases Specified in [package.json](./package.json)

#### Preparation Steps Before Executing a Load Test

##### Tweak the Load Test

According to the type of loadtest you want to execute you might want to change a few parameters before executing it, this can be done in [src/options/optionsLoadTest.ts](./src/options/optionsLoadTest.ts)

Eventually which options configuration you want to use during execution is configured in the [package.json](./package.json).

```typescript
// Example of a options configuration
export const options = {
  // Virtual users
  vus: 1,
  // Starting the duration and ramping it up slowly
  startRate: 50,
  stages: [
    { target: 200, duration: "30s" }, // linearly go from 50 iters/s to 200 iters/s for 30s
    { target: 500, duration: "0" }, // instantly jump to 500 iters/s
    { target: 500, duration: "10m" }, // continue with 500 iters/s for 10 minutes
  ],
};
```

##### Transpile the Load Test

In order to run the testcases they first need to be transpiled from TS to JS in the **_dist_** folder.

```bash
npx tsc
```

#### Run Testcases for the Different Database Instances

Make sure the dist folder contains the latest version of changes you might have made.

```bash
npm run test:car1
npm run test:car2
```
