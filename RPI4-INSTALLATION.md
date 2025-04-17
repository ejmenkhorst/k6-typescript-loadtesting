# Installation instructions RPI 4

These installation instructions

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

First login to your raspberry pi via SSH - I reccomend installing it via a LAN cable to your network your ISP might block port 22 by default on your router at home.

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

### 3. Install Portainer

Portainer is a GUI tool for managing docker containers  
[Installation instructions Portainer CE version Linux](https://docs.portainer.io/start/install-ce/server/docker/linux)

#### Portainer Server installation

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

After logging in succesfully with your new admin user

- Go to **Home** look at the **Environments** and **local** now you see you docker instance with all necesarry information.

### 4. Install Prometheus Exporter

Exporter tool to get data from your raspberry pi, t0 monitor it and show it later via a Grafana dashboard

```bash
# Install prometheus-node-exporter
sudo apt-get install prometheus-node-exporter
# Set scrape endpoint
curl "http://localhost:9100/metrics"
# Verify status
sudo systemctl status prometheus-node-exporter

```
