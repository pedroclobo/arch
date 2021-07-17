#!/bin/bash

# Source functions
source ./library.sh
source ./stdin.sh

### Configure the system

# Time zone
set_time_zone "$(get_timezone)"

# Localization
generate_locales

# Network configuration
set_hostname && set_hosts

# Root password
set_password "root" "$(get_passwd)"

# Bootloader
install "intel-ucode"
install_systemd_boot

# Install and enable Network Manager
install "networkmanager" && systemctl enable NetworkManager
