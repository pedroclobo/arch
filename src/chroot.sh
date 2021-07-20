#!/bin/bash
# Follow-up to the main file

# File dependencies
file_deps=("stdin.sh" "package.sh" "disk.sh" "system.sh")


# Source script dependencies and install missing dependencies
prepare_dependencies() {

	# Source dependency files
	for file in "${file_deps[@]}"; do
		source "$file"
	done
}


###################
### Preparation ###
###################

# Get all dependencies
prepare_dependencies


############################
### Configure the system ###
############################

# Time zone
set_timezone "$timezone"

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

# Install drivers
install_drivers "$driver"
