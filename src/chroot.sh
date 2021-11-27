#!/bin/bash
# Follow-up to the main file

# Source files and install missing dependencies
prepare_dependencies() {

	# Source files
	for file in "stdin.sh" "package.sh" "disk.sh" "system.sh"; do
		source "$file"
	done
}


###################
### Preparation ###
###################

# Prepare dependencies
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
install_bootloader "$disk" "$crypt_passwd"


#############################
### System administration ###
#############################

# User and groups / Privilege elevation
add_user "$user" "$passwd" "bash"
sudoers_uncomment "%wheel ALL=(ALL) ALL"
sudoers_uncomment "%wheel ALL=(ALL) NOPASSWD: ALL"


##########################
### Package management ###
##########################

# Pacman
pacman_configuration

# Mirrors
sort_mirrors "$country"

# Arch User Repository
install_aur_helper "$user"


###############
### Booting ###
###############

# Microcode
install_microcode


################################
### Graphical user interface ###
################################

# Display server
install_display_server "Xorg"

# Display drivers
install_drivers "$driver" "$user"

# Desktop environments / Window managers / Display manager
install_desktop "$desktop" "$user" "https://raw.githubusercontent.com/pedroclobo/arch/main/src/lib/packages.txt"


##################
### Networking ###
##################

# Install Network Manager
install "networkmanager"
systemctl enable NetworkManager


####################
### Optimization ###
####################

# Periodic TRIM
is_ssd "$disk" && enable_trim

# Set /bin/sh shell
set_shell "dash"


####################
### Finalization ###
####################

# Finish installation
finalize "$desktop"
