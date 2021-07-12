#!/bin/bash

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

	# Creating the boot, swap and root partition
	parted --script -a optimal "$DISK" \
		mklabel gpt \
		unit mib \
		mkpart primary 1 "$SIZE_1" \
		name 1 boot \
		set 1 boot on \
		-- mkpart primary "$SIZE_1" -1 \
		name 2 rootfs

	# Export disk variables
	export_variable "BOOT_PART" "$DISK""1"
	export_variable "ROOT_PART" "$DISK""2"
}

# Format the partition for UEFI with the ext4 filesystem
format_gpt() {
	yes | mkfs.vfat -F 32 "$BOOT_PART"
	yes | mkfs.ext4 "$ROOT_PART"
}

# Mount the partitions
mount_gpt() {
	mount "$ROOT_PART" /mnt
	mkdir -p /mnt/boot && mount "$BOOT_PART" /mnt/boot
}

# Install essencial packages
install_essential() {
	pacstrap /mnt base linux linux-firmware
}

generate_fstab() {
	genfstab -U /mnt >> /mnt/etc/fstab
}

change_root() {
	curl $CHROOT > /mnt/chroot.sh && 
		mv ./*.sh /mnt &&
		arch-chroot /mnt bash chroot.sh && 
		rm /mnt/chroot.sh
}

set_time_zone() {
	ln -sf /usr/share/zoneinfo/"$1" /etc/localtime
	hwclock --systohc
}

uncomment_locale() {
	sed -i "s/#"$1"/"$1"/g" /etc/locale.gen
}

set_lang_var() {
	echo "LANG=${1}" > /etc/locale.conf
	
}

set_keyboard_var() {
	echo "KEYMAP=${KEY_LAYOUT}" >> /etc/vconsole.conf
}

generate_locales() {
	[ "$COUNTRY" = "Portugal" ] && 
		uncomment_locale "en_US.UTF-8" &&
		uncomment_locale "pt_PT.UTF-8" &&
		locale-gen && set_lang_var "en_US.UTF-8" && set_keyboard_var "$KEY_LAYOUT"
}

set_hostname() {
	echo "$HOSTNAME" > /etc/hostname
}

set_hosts() {
	printf "127.0.0.1	localhost\n::1		localhost\n127.0.1.1	${HOSTNAME}.localdomain	${HOSTNAME}" >> /etc/hosts
}

create_initramfs() {
	mkinitcpio -P
}

set_password() {
	echo "${1}:${2}" | chpasswd
}

install_systemd_boot() {
	
	# Install the bootloader
	bootctl --path=/boot install

	create_loader_entry
	change_default_entry "arch"
}

change_default_entry() {
	
	sed -i "s/default.*/default\t${1}.conf/g" /boot/loader/loader.conf
}

create_loader_entry() {
	print "title\tArch\nlinux\t/vmlinuz-linux\ninitrd\t/intel-ucode.img\ninitrd\t/initramfs-linux-fallback.img\toptions root=${ROOT_PART} rw" > /boot/loader/entries/arch.conf
}
