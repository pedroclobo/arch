#!/bin/bash
# Disk functions

################################################################################
# Verify the disk is a SSD
# Arguments:
#     disk
# Returns:
#     0 if the disk in a ssd; 1, otherwise
################################################################################
is_ssd() {
	prefix=$(echo "$1" | awk -F '/' '{print $3}')
	cat /sys/block/"${prefix}"/queue/rotational > /dev/null
}

################################################################################
# Get the disk's size
# Arguments:
#     disk
# Returns:
#     size in GB
################################################################################
get_disk_size() {
	disk_sizes=$(lsblk -l | awk '/disk/ {print "/dev/"$1, $4}')

	size=$(echo "$disk_sizes" | grep "$1" | awk '{print $2}')
	echo "$size"
}

################################################################################
# Partition the disks
################################################################################
partition_disks() {
	if is_uefi_system; then
		partition_gpt "$disk"
	else
		partition_mbr "$disk"
	fi
}

################################################################################
# Partition the disks for MBR layouts
# Arguments:
#     disk
################################################################################
partition_mbr() {
	size_1=$((1 + 256))

	parted --script -a optimal "$1" \
		mklabel msdos \
		unit mib \
		mkpart primary 1 "$size_1" \
		-- mkpart primary "$size_1" -1

	export BOOT_PART="$1""1"
	export ROOT_PART="$1""2"
}

################################################################################
# Partition the disks for GPT layouts
# Arguments:
#     disk
################################################################################
partition_gpt() {
	size_1=$((1 + 256))

	parted --script -a optimal "$1" \
		mklabel gpt \
		unit mib \
		mkpart primary 1 "$size_1" \
		name 1 boot \
		set 1 boot on \
		-- mkpart primary "$size_1" -1 \
		name 2 root

	export BOOT_PART="$1""1"
	export ROOT_PART="$1""2"
}

################################################################################
# Format the partitions
# Arguments:
#     encryption password
################################################################################
format_partitions() {
	if is_uefi_system; then
		if [[ "$1" == "" ]]; then
			format_gpt
		else
			format_gpt_crypt "$1"
		fi
	else
		if [[ "$1" == "" ]]; then
			format_mbr
		else
			format_mbr_crypt "$1"
		fi
	fi
}

################################################################################
# Format the partitions for MBR layout with the ext4 filesystem
# Globals:
#     BOOT_PART
#     ROOT_PART
################################################################################
format_mbr() {
	yes | mkfs.ext4 "$BOOT_PART"
	yes | mkfs.ext4 "$ROOT_PART"
}

################################################################################
# Format and encrypt the partitions for MBR layout with the ext4 filesystem
# Globals:
#     BOOT_PART
# Arguments:
#     encryption password
################################################################################
format_mbr_crypt() {
	yes | mkfs.ext4 "$BOOT_PART"
	encrypt_root "$1"
	yes | mkfs.ext4 /dev/mapper/cryptroot
}

################################################################################
# Format the partitions for GPT layout with the ext4 filesystem
# Globals:
#     BOOT_PART
#     ROOT_PART
################################################################################
format_gpt() {
	yes | mkfs.vfat -F 32 "$BOOT_PART"
	yes | mkfs.ext4 "$ROOT_PART"
}

################################################################################
# Format and encrypt the partitions for GPT layout with the ext4 filesystem
# Globals:
#     BOOT_PART
# Arguments:
#     encryption password
################################################################################
format_gpt_crypt() {
	yes | mkfs.vfat -F 32 "$BOOT_PART"
	encrypt_root "$1"
	yes | mkfs.ext4 /dev/mapper/cryptroot
}

################################################################################
# Mount the filesystems
# Arguments:
#     encryption password
################################################################################
mount_filesystems() {
	if is_uefi_system; then
		if [[ "$1" == "" ]]; then
			mount_gpt
		else
			mount_gpt_crypt
		fi
	else
		if [[ "$1" == "" ]]; then
			mount_mbr
		else
			mount_mbr_crypt
		fi
	fi
}

################################################################################
# Mount the filesystems for MBR layout with ext4 root partition
# Globals:
#     BOOT_PART
#     ROOT_PART
################################################################################
mount_mbr() {
	mount "$ROOT_PART" /mnt
	mkdir -p /mnt/boot && mount "$BOOT_PART" /mnt/boot
	create_swapfile
}

################################################################################
# Mount the filesystems for MBR layout with encrypted ext4 root partition
# Globals:
#     BOOT_PART
################################################################################
mount_mbr_crypt() {
	mount /dev/mapper/cryptroot /mnt
	mkdir -p /mnt/boot && mount "$BOOT_PART" /mnt/boot
	create_swapfile
}

################################################################################
# Mount the filesystems for GPT layout with ext4 root partition
# Globals:
#     BOOT_PART
#     ROOT_PART
################################################################################
mount_gpt() {
	mount "$ROOT_PART" /mnt
	mkdir -p /mnt/boot && mount "$BOOT_PART" /mnt/boot
	create_swapfile
}

################################################################################
# Mount the filesystems for GPT layout with encrypted ext4 root partition
# Globals:
#     BOOT_PART
################################################################################
mount_gpt_crypt() {
	mount /dev/mapper/cryptroot /mnt
	mkdir -p /mnt/boot && mount "$BOOT_PART" /mnt/boot
	create_swapfile
}

################################################################################
# Create a swapfile and activate it
################################################################################
create_swapfile() {

	# Swap is twice the size of the RAM
	size=$(( 2 * "$(get_ram_size)" ))

	dd if=/dev/zero of=/mnt/swapfile bs=1M count=${size} status=progress
	chmod 600 /mnt/swapfile
	mkswap /mnt/swapfile
	swapon /mnt/swapfile
}

################################################################################
# Encrypt the root partition
# Globals:
#     ROOT_PART
# Arguments:
#     encryption password
################################################################################
encrypt_root() {
	echo "$1" | cryptsetup -q luksFormat "$ROOT_PART"
	echo "$1" | cryptsetup open "$ROOT_PART" cryptroot
}
