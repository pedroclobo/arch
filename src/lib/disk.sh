#!/bin/bash
# File with all disk related functions

# Boot partition size in MB
BOOT_SIZE="260"


# Return the size of the given disk
get_disk_size() {

	# Variable with all disks and their sizes
	disk_sizes=$(lsblk -l | awk '/disk/ {print "/dev/"$1, $4}')

	# Get the size
	size=$(echo "$disk_sizes" | grep "$1" | awk '{print $2}')

	echo "$size"
}

# Partition the disk with MBR for BIOS / Legacy boot
partition_mbr() {
	SIZE_1=$((1 + BOOT_SIZE))
	SIZE_2=$((SIZE_1 + SWAP_SIZE))

	parted --script -a optimal "$disk" \
		mklabel msdos \
		unit mib \
		mkpart primary "$SIZE_1" "$SIZE_2" \
		-- mkpart primary "$SIZE_2" -1 \

	# Export disk variables
	BOOT_PART="$disk""1" && export BOOT_PART
	SWAP_PART="$disk""2" && export SWAP_PART
	ROOT_PART="$disk""3" && export ROOT_PART
}

# Partition the disk with GPT for UEFI
partition_gpt() {
	SIZE_1=$((1 + BOOT_SIZE))

	# Creating the boot, swap and root partition
	parted --script -a optimal "$disk" \
		mklabel gpt \
		unit mib \
		mkpart primary 1 "$SIZE_1" \
		name 1 boot \
		set 1 boot on \
		-- mkpart primary "$SIZE_1" -1 \
		name 2 rootfs

	# Export disk variables
	BOOT_PART="$disk""1" && export BOOT_PART
	ROOT_PART="$disk""2" && export ROOT_PART
}

# Partition the disk
partition_disks() {

	if is_uefi_system; then
		partition_gpt
	else
		partition_mbr
	fi
}

# Format the partition for UEFI with the ext4 filesystem
format_gpt() {

	yes | mkfs.vfat -F 32 "$BOOT_PART"
	yes | mkfs.ext4 "$ROOT_PART"
}

# Format the partition for UEFI with the ext4 filesystem
format_gpt_crypt() {

	yes | mkfs.vfat -F 32 "$BOOT_PART"
	encrypt_root
	yes | mkfs.ext4 /dev/mapper/cryptroot
}

# Format the partitions
format_partitions() {

	if is_uefi_system; then
		if [ "$crypt_passwd"  = "" ]; then
			format_gpt
		else
			format_gpt_crypt
		fi
#	else
#		partition_mbr
	fi
}

# Mount the partitions
mount_gpt() {

	mount "$ROOT_PART" /mnt
	mkdir -p /mnt/boot && mount "$BOOT_PART" /mnt/boot
	create_swapfile
}

# Mount the partitions
mount_gpt_crypt() {

	mount /dev/mapper/cryptroot /mnt
	mkdir -p /mnt/boot && mount "$BOOT_PART" /mnt/boot
	create_swapfile
}

# Mount the file systems
mount_filesystems() {

	if is_uefi_system; then
		if [ "$crypt_passwd"  = "" ]; then
			mount_gpt
		else
			mount_gpt_crypt
		fi
#	else
#		partition_mbr
	fi
}

