# Installation instructions RPI 4

These installation instructions

## Installation on SD card

- Insert SD card and download the tool [Raspberry Pi Imager](https://www.raspberrypi.com/software/)
- Install Raspberry Pi OS

  - Go to Raspberry Pi OS Other
  - Select: Raspberry Pi OS Lite 64 bit latest release(2024-11-19) -> press next
  - When prompted **edit the default settings** as described below

  ### Change default settings

  - Set hostname: raspberry.local
  - Set username and password
    - Username: **pi**
    - Password: **your secret admin password**
  - Configure wireless LAN
    - SSID: **your network of choice**
    - Password: **your secret password of choice**
    - Wireless LAN country: **NL**
  - Set locale settings
    - Timezone: **Europe/Amsterdam**
    - Keyboard layout: **NL**

## Install software on RPI 4

To use the RPI4 the following software listed below needs to be installed.

### 1. Login to RPI via SSH

To be able to connect via SSH you first need to create an [empty SSH file](https://www.raspberrypi.com/documentation/computers/remote-access.html#enable-the-ssh-server)

```bash
cd media/your_username/rootfs/boot/firmware
sudo touch ssh
# Check if SSH file is created
ls
# Output should be a SSH file
```

First login to your raspberry pi via SSH

```bash
cd media/erik-menkhorst/rootfs/boot/firmware
sudo touch ssh

# SSH into raspberry pi
ssh pi@raspberrypi4.local
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

### 3. Install Portainer

GUI tool for managing docker containers

```bash
docker-compose up --build -d
```
