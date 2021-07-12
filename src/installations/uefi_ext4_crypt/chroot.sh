#!/bin/bash

# Source functions
source ./library.sh
source ./stdin.sh
source "$VAR_FILE"

### Configure the system

# Time zone
set_time_zone "$TIME_ZONE"

# Localization
generate_locales

# Network configuration
set_hostname && set_hosts

# Initramfs
create_initramfs

# Root password
set_password "root" "$PASSWD"

# Bootloader
install "intel-ucode"
install_systemd_boot

# Install and enable Network Manager
install "networkmanager" && systemctl enable NetworkManager
