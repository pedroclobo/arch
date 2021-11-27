#!/bin/bash
# Main install script

# Source files and install missing dependencies
prepare_dependencies() {

	# Source files
	for file in "stdin.sh" "package.sh" "disk.sh" "system.sh"; do
		source "$file"
	done

	# Install dependencies
	sync_mirrors && install_silently "wget"
}


###################
### Preparation ###
###################

# Prepare dependencies
prepare_dependencies

# Get user input
get_user_input


########################
### Pre-Installation ###
########################

# Set the console keyboard layout
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
sort_mirrors "$country"

# Install essential packages
install_essential "base linux linux-headers linux-firmware base-devel"


############################
### Configure the system ###
############################

# Fstab
generate_fstab

# Chroot
change_root "https://raw.githubusercontent.com/pedroclobo/arch/main/src/chroot.sh"
