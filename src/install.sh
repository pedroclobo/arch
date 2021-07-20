#!/bin/bash
# Main file

# File dependencies
file_deps=("stdin.sh" "package.sh" "disk.sh" "system.sh")

# Chroot script link
CHROOT="https://raw.githubusercontent.com/pedroclobo/arch/main/src/chroot.sh"


# Source script dependencies and install missing dependencies
prepare_dependencies() {

	# Source dependency files
	for file in "${file_deps[@]}"; do
		source "$file"
	done

	# Install dependencies
	! is_installed "wget" && install "wget"
}


###################
### Preparation ###
###################

# Get all dependencies
prepare_dependencies


##################
### User Input ###
##################

# Get user input
get_user_input


########################
### Pre-Installation ###
########################

# Set the keyboard layout
set_keymap "$keymap"

# Update the system clock
update_clock

# Partition the disks
partition_disks

# Format the partitions
format_partitions

# Mount the file systems
mount_filesystems


####################
### Installation ###
####################

# Select the mirrors
update_mirrors "$country"

# Install essential packages
install_essential


############################
### Configure the system ###
############################

# Fstab
generate_fstab

# Chroot
change_root
