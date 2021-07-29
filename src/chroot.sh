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
generate_locales "$country" "$keymap"

# Network configuration
set_hostname "$hostname" && add_hosts "$hostname"

# Root password
set_password "root" "$passwd"

# Bootloader
install_microcode
install_systemd_boot "$crypt_passwd"


#############################
### System administration ###
#############################

# User and groups and Privilege elevation
add_user "$user" "$passwd" "bash"
sudoers_uncomment "%wheel ALL=(ALL) ALL"
sudoers_uncomment "%wheel ALL=(ALL) NOPASSWD: ALL"

# Package management
install_aur_helper "$user"


################################
### Graphical user interface ###
################################

# Display server
install_display_server "Xorg"

# Display drivers
install_drivers "$driver" "$user"

# Desktop environments / Window managers
install_desktop "$desktop" "$user"


#####################
### Miscellaneous ###
#####################

# Apply tweaks
apply_tweaks "dash" "$disk" "$country"

# Finish installation
sudoers_comment "%wheel ALL=(ALL) NOPASSWD: ALL"
