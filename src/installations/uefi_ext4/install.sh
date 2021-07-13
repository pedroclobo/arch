#!/bin/bash

# Follow-up chroot script
CHROOT="https://raw.githubusercontent.com/pedroclobo/arch/main/src/installations/uefi_ext4/chroot.sh"

# Define boot partition size in MB
BOOT_SIZE="260"

# Source functions
source ./library.sh
source ./stdin.sh
source "$VAR_FILE"


### Pre-installation

# Update the system clock
update_clock

# Partition the disks
partition_gpt

# Format the partitions
format_gpt

# Mount the file systems
mount_gpt


### Installation

# Select the mirrors
update_mirrors "$COUNTRY"

# Install essential packages
install_essential


### Configure the system

# Fstab
generate_fstab

# Chroot
change_root