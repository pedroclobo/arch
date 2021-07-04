#!/bin/bash

BOOT_SIZE="260"
REPO_ZIP="https://github.com/pedroclobo/arch/archive/refs/heads/main.zip"


# Check if the boot mode if UEFI
is_uefi_system() {
	[ -d "/sys/firmware/efi/efivars" ]
}

# Install a package through pacman
install() {
	pacman -S $@ --noconfirm
}

# Sincronize mirrors
refresh_mirrors() {
	pacman -Syy
}

# Check if a package is installed
is_installed() {
	pacman -Qnq | grep -q -wx $1
}

# Sort pacman mirrors based on speed and location
# and refresh them
update_mirrors() {
	reflector -c "$1" -a 6 --sort rate --save /etc/pacman.d/mirrorlist
	refresh_mirrors
}

# List all available keyboard layouts
list_keyboard_layouts() {
	localectl list-keymaps
}

# Set keyboard layout
set_keyboard_layout() {
	loadkeys $1
}

# Recognizes a keyboard layout
is_keyboard_layout() {
	localectl list-keymaps | grep -q -wx "$1"
}

# List all disks available and their sizes
list_disks() {
	lsblk -l | grep disk | awk '{print "/dev/"$1, "(" $4 ")"}'
}

# Check for a valid disk
is_disk() {
	lsblk -l | grep disk | awk '{print "/dev/"$1}' | grep -q -wx "$1"
}


list_filesystems() {
	echo "ext4"
}

is_filesystem() {
	list_filesystems | grep -q -wx "$1"
}

list_timezones() {
	timedatectl list-timezones
}

is_timezone() {
	list_timezones | grep -q -wx "$1"
}

# Update the system clock
update_clock() {
	timedatectl set-ntp true
}

# Partition the disk with MBR for BIOS / Legacy boot
partition_mbr() {
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

# Partition the disk with GPT for UEFI
partition_gpt() {
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

# Format the partition for UEFI with the ext4 filesystem
format_uefi() {
	yes | mkfs.vfat -F 32 "$BOOT_PART"
	yes | mkfs.ext4 "$ROOT_PART"
	mkswap "$SWAP_PART"
	swapon "$SWAP_PART"
}

# Check if the system supports UEFI
export_uefi_variable() {
is_uefi_system && 
	export_variable "UEFI" 1 ||
	export_variable "UEFI" 0
}

# Initilize the installer
initialize_installer() {

	# Download necessary files and source them
	refresh_mirrors && install "wget" "unzip"
	wget "$REPO_ZIP"
	unzip *.zip && mv ./arch-main/*.sh . && \
		rm -f *.zip && rm -rf ./arch-main && \
		chmod +x *.sh
	source *.sh

	# Check for UEFI support
	export_uefi_variable
}

###################
### Instalation ###
###################

# Prepare the installer
initialize_installer

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

