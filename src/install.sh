#!/bin/bash
# Main install script

# File dependencies
file_deps=("stdin.sh" "package.sh" "disk.sh" "system.sh")

export BOOT_SIZE=260
export CHROOT="https://raw.githubusercontent.com/pedroclobo/arch/main/src/chroot.sh"
export PACKAGE_LIST="https://raw.githubusercontent.com/pedroclobo/arch/main/src/lib/packages.txt"
export AUR_HELPER="paru"
export ESSENTIAL_PACKAGES="base linux linux-headers linux-firmware base-devel"

# Source script dependencies and install missing dependencies
prepare_dependencies() {

	# Source dependency files
	for file in "${file_deps[@]}"; do
		source "$file"
	done

	# Install dependencies
	! is_installed "wget" && sync_mirrors && install_silently "wget"
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

# Load the keyboard layout
load_keymap "$keymap"

# Update the system clock
update_clock

# Partition the disks
partition_disks "$disk"

# Format the partitions
format_partitions "$crypt_passwd"

# Mount the file systems
mount_filesystems "$crypt_passwd"


####################
### Installation ###
####################

# Select the mirrors
update_mirrors "$country"

# Install essential packages
install_essential "$ESSENTIAL_PACKAGES"


############################
### Configure the system ###
############################

# Fstab
generate_fstab

# Chroot
change_root
