#!/bin/bash

# Source functions
source ./library.sh
source ./stdin.sh

# Check if the system supports UEFI
export_uefi_variable() {
is_uefi_system && 
	export_variable "UEFI" 1 ||
	export_variable "UEFI" 0
}

# Initialize the script
initialize_script() {

	# Check for UEFI support
	export_uefi_variable
}

# Initilize the installer based on the choosen filesystem
initialize_installer() {
}

###################
### Instalation ###
###################

# Prepare the installer
initialize_script

# Get user input
get_keyboard_layout
get_country
get_disks
get_filesystem
get_crypt_passwd
get_hostname
get_passwd
get_timezone
get_confirmation
source "$VAR_FILE"

# Initialize the installer
initialize_installer
