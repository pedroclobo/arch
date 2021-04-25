#!/bin/bash

# Write variable to variables file
export_variable() {
	VAR_NAME=$1
	shift;
	VAR=$*

	echo "$VAR_NAME=$VAR" >> ./variables
	source ./variables
}

# Prompt the user for a variable and write it to the variables file
get_variable() {
	VAR_NAME=$1
	shift;
	MESSAGE=$*
	clear

	# Prompt the user for the variable
	echo "$MESSAGE"
	read -r VAR

	# Export the variable
	export_variable "$VAR_NAME" "$VAR"

	# Re-clear the screen
	clear
}


# Check if the boot mode is uefi and write corresponding variable
get_uefi_system_variable() {
	if [ -d "/sys/firmware/efi/efivars" ]
	then
		export_variable "UEFI" 1
	else
		export_variable "UEFI" 0
fi

	# Source variables file at the end
	source ./variables
}

# Returns true if the boot mode if UEFI
is_uefi_system() {
	if [[ $UEFI = 1 ]]
	then
		return 1
	else
		return 0
	fi
}

# Disk partitioning with MBR for BIOS / Legacy boot
partition_legacy() {

	SIZE_1=$((1 + BOOT_SIZE))
	SIZE_2=$((SIZE_1 + SWAP_SIZE))

	parted --script -a optimal "$DISK" \
		mklabel msdos \
		unit mib \
		mkpart primary 1 "$SIZE_1" \
		mkpart primary "$SIZE_1" "$SIZE_2" \
		-- mkpart primary "$SIZE_2" -1 \

	# Export disk variables
	export_variable BOOT_PART "$DISK""1"
	export_variable SWAP_PART "$DISK""2"
	export_variable ROOT_PART "$DISK""3"
}

# Disk partitioning with GPT for UEFI
partition_uefi() {

	SIZE_1=$((1 + BOOT_SIZE))
	SIZE_2=$((SIZE_1 + SWAP_SIZE))

	# Creating the boot, swap and root partition
	parted --script -a optimal "$DISK" \
		mklabel gpt \
		unit mib \
		mkpart primary 1 "$SIZE_1" \
		name 1 boot \
		set 1 boot on \
		mkpart primary "$SIZE_1" "$SIZE_2" \
		name 2 swap \
		-- mkpart primary "$SIZE_2" -1 \
		name 3 rootfs

	# Export disk variables
	export_variable BOOT_PART "$DISK""1"
	export_variable SWAP_PART "$DISK""2"
	export_variable ROOT_PART "$DISK""3"
}


# Format the partition for UEFI 
# with the BTRFS filesystem
format_uefi() {
	yes | mkfs.vfat -F 32 "$BOOT_PART"
	yes | mkfs.ext4 "$ROOT_PART"
	mkswap "$SWAP_PART"
	swapon "$SWAP_PART"
}


# Sorts the mirrors by speed and writes the output to the mirrorlist file
sort_mirrors() {
	reflector -c "$1" -a 6 --sort rate --save /etc/pacman.d/mirrorlist
}


##################
### User Input ###
##################

# Prompt for the disk device to install the OS to
DISKS=$(lsblk -l | grep disk | awk '{print "\t/dev/"$1, "\t" $4}')
get_variable DISK "What disk do you want to install the OS to?\n$DISKS\n--> "

# Prompt for the boot partition size
get_variable BOOT_SIZE "Enter boot partition size (in MB)\n--> "

# Prompt for the swap partition size
get_variable SWAP_SIZE "Enter swap size? (in MB)\n--> "

# Prompt for the hostname
get_variable HOSTNAME "What hostname?\n--> "

# Prompt for the root password
get_variable PASSWORD "Enter root password\n--> "


########################
### Pre-Installation ###
########################

# Verify the boot mode
get_uefi_system_variable

# Update the system clock
timedatectl set-ntp true

# Partition the disks
if [ "$is_uefi_system" ]
then
	partition_uefi
else
	partition_legacy
fi

# Format the partitions
if [ "$is_uefi_system" ]
then
	format_uefi
else
	format_legacy
fi


####################
### Installation ###
####################

# Select the mirrors
sort_mirrors "Portugal"
