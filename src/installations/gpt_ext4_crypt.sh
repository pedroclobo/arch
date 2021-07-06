#!/bin/bash

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
format_uefi

# Mount the file systems
mount_gpt


### Installation

# Select the mirrors
update_mirrors "$COUNTRY"
