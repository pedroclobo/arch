#!/bin/bash
# File with all install related functions

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

# Set keyboard layout
set_keyboard_layout() {
	loadkeys $1
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

	# Non-encrypted
	[ "$CRYPT_PASSWD" = "" ] &&
		yes | mkfs.vfat -F 32 "$BOOT_PART" &&
		yes | mkfs.ext4 "$ROOT_PART"

	# Encrypted
	! [ "$CRYPT_PASSWD" = "" ] &&
		yes | mkfs.vfat -F 32 "$BOOT_PART" &&
		encrypt_root &&
		yes | mkfs.ext4 /dev/mapper/cryptroot
}

# Mount the partitions
mount_gpt() {

	# Non-encrypted
	[ "$CRYPT_PASSWD" = "" ] &&
		mount "$ROOT_PART" /mnt && 
		mkdir -p /mnt/boot && mount "$BOOT_PART" /mnt/boot

	# Encrypted
	! [ "$CRYPT_PASSWD" = "" ] &&
		mount /dev/mapper/cryptroot /mnt &&
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
		mv ./* /mnt &&
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

# Set hostname
set_hostname() {
	echo "$HOSTNAME" > /etc/hostname
}

# Create hosts file
set_hosts() {
cat <<EOF > /etc/hosts
127.0.0.1	localhost
::1			localhost
127.0.1.1	${HOSTNAME}.localdomain	${HOSTNAME}
EOF
}

# Create initramfs
create_initramfs() {
	mkinitcpio -P
}

# Set the password for the given user
set_password() {
	echo "${1}:${2}" | chpasswd
}

# Install systemd-boot
install_systemd_boot() {

	# Install the bootloader
	bootctl --path=/boot install

	# Create the loader entry and make it default
	create_loader_entry
	change_default_entry "arch"

	# Change hooks if encryption is choosen
	! [ "$CRYPT_PASSWD" = "" ] &&
		sed -i "s/HOOKS=.*/HOOKS=(base systemd autodetect keyboard sd-vconsole modconf block sd-encrypt filesystems fsck)/g" /etc/mkinitcpio.conf &&
		create_initramfs
}

# Change systemd-boot default loader entry
change_default_entry() {

	sed -i "s/default.*/default\t${1}.conf/g" /boot/loader/loader.conf
}

# Create systemd-boot loader entry
create_loader_entry() {

	[ "$CRYPT_PASSWD" = "" ] &&
cat <<EOF > /boot/loader/entries/arch.conf
title	Arch
linux	/vmlinuz-linux
initrd	/intel-ucode.img
initrd	/initramfs-linux-fallback.img
options root=${ROOT_PART} rw
EOF

	! [ "$CRYPT_PASSWD" = "" ] &&
		UUID=$(blkid | grep /dev/sda2 | awk {'print $2'} | awk -F '"' {'print $2'}) &&
cat <<EOF > /boot/loader/entries/arch.conf
title	Arch
linux	/vmlinuz-linux
initrd	/intel-ucode.img
initrd	/initramfs-linux-fallback.img
options rd.luks.name=${UUID}=cryptroot root=/dev/mapper/cryptroot rw
EOF

}

# Encrypt the root partition
encrypt_root() {

	# Encrypt the partition
	echo "$CRYPT_PASSWD" | cryptsetup -q luksFormat "$ROOT_PART"

	# Open the partition
	echo "$CRYPT_PASSWD" | cryptsetup open "$ROOT_PART" cryptroot
}

get_disk_size() {
	
	disk_sizes=$(lsblk -l | awk '/disk/ {print "/dev/"$1, $4}')
	size=$(echo $disk_sizes | grep "$1" | awk '{print $2}')

	echo "$size"
}
