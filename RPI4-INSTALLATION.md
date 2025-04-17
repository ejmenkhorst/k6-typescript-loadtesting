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
  - Configure wireless LAN (make sure port 22 is opened on your network)
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
# SSH into raspberry pi
ssh pi@raspberrypi.local
```

### 2. Install Docker

```bash
# Update your dependencies first
sudo apt update
sudo apt upgrade

# Install Docker
curl -sSL https://get.docker.com | sh
# Setup user for Docker

```

### 3. Install Prometheus Exporter

Exporter tool to get data from your raspberry pi, t0 monitor it and show it later via a Grafana dashboard

```bash

```

### 4. Install Portainer

GUI tool for managing docker containers

```bash

```
