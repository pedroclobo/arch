#!/bin/bash

# Source functions
source ./library.sh

### Configure the system

# Time zone
set_time_zone "$timezone"

# Localization
generate_locales

# Network configuration
set_hostname && set_hosts

# Root password
set_password "root" "$passwd"

# Bootloader
install "intel-ucode"
install_systemd_boot

# Install and enable Network Manager
install "networkmanager" && systemctl enable NetworkManager
