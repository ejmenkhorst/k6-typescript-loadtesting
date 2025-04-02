# k6-typescript-loadtesting
Portfolio project Grafana K6 load testing with TypeScript.

## Project setup

### Setup Guide

1. **Build Docker Image For Executing Shell Scripts:**

   ```bash
   docker build -t couchdb-bash-setup-image .
   
2. **Initialise all containers**

   ```bash
   docker-compose up --build -d  

## Test Data

## Execution order when executing Docker-Compose up

- chmod +x init-scripts/initial-setup.sh
- curl -X PUT -u admin:A24cvmri http://localhost:5984/_users -> create _user database via curl command
- curl -X GET -u admin:A24cvmri http://localhost:5984/_up
### CouchDB web UI

v
### Access the services:

- CouchDB UI: Access the CouchDB web interface at http://localhost:5984.
- Prometheus UI: Access Prometheus at http://localhost:9090.
- Grafana UI: Access Grafana at http://localhost:3000 (default username: admin, password: adminpassword).

### Configure Grafana:

Once in the Grafana UI, you'll need to set up Prometheus as a data source:
Go to Configuration -> Data Sources -> Add Data Source.
Select Prometheus and set the URL to http://prometheus:9090.
After adding the data source, you can create dashboards to visualize the metrics collected from CouchDB.
