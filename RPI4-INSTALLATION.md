# Installation instructions RPI 4

## Table of Contents

1. [Installation on SD card](#installation-on-sd-card)
   - [Change default settings](#change-default-settings)
2. [Install software on RPI 4](#install-software-on-rpi-4)
   - [Login to RPI via SSH](#1-login-to-rpi-via-ssh)
   - [Install Docker](#2-install-docker)
   - [Install Portainer](#3-install-portainer-server)
   - [Install Prometheus Exporter](#4-install-prometheus-exporter)
   - [Install CouchDB via Portainer](#5-install-couchdb-via-portainer)
     - [Create a new volume for database data](#create-a-new-volume-for-database-data)
     - [Create a local.ini file on RPI](#create-a-localini-file-on-rpi)
     - [Set up the CouchDB container](#set-up-the-couchdb-container)
       - [Volumes](#volumes)
       - [Network](#network)
       - [Env](#env)
       - [Restart policy](#restart-policy)
       - [Runtime & resources](#runtime--resources)
3. [Necessary adjustments](#necessary-adjustments)
   - [Modify .env](#modify-env)
   - [Docker Compose](#docker-compose)

## Installation on SD card

- Insert SD card and download the tool [Raspberry Pi Imager](https://www.raspberrypi.com/software/)
- Install Raspberry Pi OS

  - Go to Raspberry Pi OS Other
  - Select: Raspberry Pi OS Lite 64 bit latest release(2024-11-19) -> press next
  - When prompted **edit the default settings** as described below -> afterward changing these setting click on **yes** to apply them and wait for the installation to finish

  ### Change default settings

  - Set hostname: raspberrypi.local
  - Set username and password
    - Username: **pi**
    - Password: **your secret admin password**
  - Configure wireless LAN (make sure port 22 is opened on your network) / Else skip this and use your LAN as a connection
    - SSID: **your network of choice**
    - Password: **your secret password of choice**
    - Wireless LAN country: **NL**
  - Set locale settings
    - Timezone: **Europe/Amsterdam**
    - Keyboard layout: **NL**

## Install software on RPI 4

To use the RPI4 the following software listed below needs to be installed.

### 1. Login to RPI via SSH

First login to your Raspberry Pi via SSH - I recommend installing it via a LAN cable to your network your ISP might block port 22 by default on your router at home.

```bash
# Find IP of your raspberry PI
ping raspberrypi.local

# SSH into Raspberry PI by hostname or IP
ssh pi@raspberrypi.local
```

### 2. Install Docker

```bash
# Update your dependencies first
sudo apt update
sudo apt upgrade

# Install Docker
curl -sSL https://get.docker.com | sh
# Setup pi user to docker group - so the user is allowed to run docker containers
sudo usermod -aG docker pi
# Reboot to make sure the changes are applied
sudo reboot
```

### 3. Install Portainer Server

Portainer is a GUI tool for managing docker containers  
[Installation instructions Portainer CE version Linux](https://docs.portainer.io/start/install-ce/server/docker/linux)

```bash
# Create the volume that Portainer Server will use to store its database
docker volume create portainer_data
# Pull the portainer docker image
sudo docker pull portainer/portainer-ce:latest
# Spinup and setup Portainer to start automatically after a restart
docker run -d -p 8000:8000 -p 9443:9443 --name=portainer --restart=always -v /var/run/docker.sock:/var/run/docker.sock -v portainer_data:/data portainer/portainer-ce:latest

```

- Verify Portainer is running
  - Go to: [https://raspberrypi.local:9443](https://raspberrypi.local:9443)
  - Create a new admin user and password

After logging in successfully with your new admin user

- Go to **Home** look at the **Environments** and **local** now you see you docker instance with all necesarry information.

### 4. Install Prometheus Exporter

Exporter tool to get data from your Raspberry Pi, to monitor it and show it later via a Grafana dashboard

```bash
# Install prometheus-node-exporter
sudo apt-get install prometheus-node-exporter
# Set scrape endpoint
curl "http://localhost:9100/metrics"
# Verify status
sudo systemctl status prometheus-node-exporter

```

### 5. Install CouchDB via Portainer

- Login to [portainer](https://raspberrypi.local:9443)

- Download the following image:
  - **couchdb:2.3.1**

#### Create a new volume for database data

- Create a new volume: **couchdb-data**

#### Create a local.ini file on RPI

For reading the configuration file with the settings we need to create a .ini file:

```bash
# SSH into the RPI
ssh pi@192.168.178.170
# Create a new directory on the RPI main volume
mkdir couchdb-config
# Create a .ini file
nano car2.ini
# Copy the same ini file from ./config/car2/local.ini
# Exit nano with ctrl+x and save the file with filename: car2.ini
```

#### Set up the CouchDB container

We are going to use the same configuration as Car 2 in our current docker-compose configuration:

- Container name: **couchdb-car2**
- Image: **couchdb:2.3.1**
- Port mapping: Host: **5986** Container: **5984**

##### Volumes

- Volume: **Map** container path: **/opt/couchdb/data** to newly created volume **couchdb-data**
- Volume: **Bind** container path: **/opt/couchdb/etc/local.d/local.ini** to host path **/home/pi/couchdb-config/car2.ini**

##### Network

- Network: **Bridge**
- Hostname: **raspberrypi.local**

##### Env

Variables:

- Name: **COUCHDB_URI** Value **http://admin:ouPFQ6mj@raspberrypi.local:5984**
- Name: **COUCHDB_USER** Value **admin**
- Name: **COUCHDB_PASSWORD** Value **ouPFQ6mj**

##### Restart policy

- Restart: Always

##### Runtime & resources

- Memory reservation: **256 MB**
- Memory limit (MB): **256 MB**
- Maximum CPU usage: **4 CPU**

Press button **Deploy the container**

After you press deploy container you should be able to access the DB via [http://raspberrypi.local:5986/](http://raspberrypi.local:5986/)  
You can also access the CouchDB web interface [car2](http://raspberrypi.local:5986/_utils/#login) with the admin credentials provided in [car2.ini](./config/car2/local.ini).

## Necessary adjustments

### Modify .env

Change the DB Car 2 container name to the IP address of your Raspberry Pi.

```env
DB_CAR2=192.168.178.170:5986
```

### Docker Compose

Make small adjustments to your docker-compose.yml file

```yml
# init-couchdb -> line 25: remove the reference to couchdb-car2

# Remove the whole service couchdb-car2 -> this is now running on your Raspberry Pi
```
