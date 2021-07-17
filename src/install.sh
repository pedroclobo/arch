#!/bin/bash

# Source functions
source ./library.sh
source ./stdin.sh

# Installation files
UEFI_EXT4="https://raw.githubusercontent.com/pedroclobo/arch/main/src/installations/uefi_ext4/install.sh"
UEFI_EXT4_CRYPT="https://raw.githubusercontent.com/pedroclobo/arch/main/src/installations/uefi_ext4_crypt/install.sh"

# Execute installer script
execute_installer() {

	# Download the installer
	wget -q "$1" -O "installer.sh"

	# Make it executable and run it
	chmod +x ./installer.sh && bash installer.sh
}

# Initilize the installer based on the choosen filesystem
initialize_installer() {

	# Various installs
	if is_uefi_system; then
		if [ "$(get_filesystem)" = "ext4" ]; then
			if [ "$(get_cryptpasswd)" = "" ]; then
				execute_installer "$UEFI_EXT4"
			else
				execute_installer "$UEFI_EXT4_CRYPT"
			fi
		fi
	fi
}

###################
### Instalation ###
###################

# Clear the screen
clear

# Get user input
create_varfile
prompt_keymap
prompt_country
prompt_disk
prompt_filesystem
prompt_crypt_passwd
prompt_hostname
prompt_passwd
prompt_timezone
prompt_confirmation

# Initialize the installer
initialize_installer
