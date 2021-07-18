#!/bin/bash
# File with all primative functions

# Check if the boot mode if UEFI
is_uefi_system() {
	[ -d "/sys/firmware/efi/efivars" ]
}

# Install a package through pacman
install() {
	pacman -S "$@" --noconfirm
}

# Refresh pacman mirrors
refresh_mirrors() {
	pacman -Syy
}

# Check if a package is installed
is_installed() {
	pacman -Qnq | grep -q -wx "$1"
}

# Sort pacman mirrors based on speed
# and location and refresh them
update_mirrors() {
	reflector -c "$1" -a 6 --sort rate --save "/etc/pacman.d/mirrorlist"
	refresh_mirrors
}

# Set keyboard layout
set_keyboard_layout() {
	loadkeys "$1"
}

# Update the system clock
update_clock() {
	timedatectl set-ntp true
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

# Format the partition for UEFI with the ext4 filesystem
format_gpt() {

	# Non-encrypted
	if [ "$crypt_passwd" = "" ]; then
		yes | mkfs.vfat -F 32 "$BOOT_PART"
		yes | mkfs.ext4 "$ROOT_PART"
		create_swapfile

	# Encrypted
	else
		yes | mkfs.vfat -F 32 "$BOOT_PART"
		encrypt_root
		yes | mkfs.ext4 /dev/mapper/cryptroot
		create_swapfile
	fi
}

# Mount the partitions
mount_gpt() {

	# Non-encrypted
	if [ "$crypt_passwd" = "" ]; then
		mount "$ROOT_PART" /mnt
		mkdir -p /mnt/boot && mount "$BOOT_PART" /mnt/boot

	# Encrypted
	else
		mount /dev/mapper/cryptroot /mnt
		mkdir -p /mnt/boot && mount "$BOOT_PART" /mnt/boot
	fi
}

# Install essencial packages
install_essential() {
	pacstrap /mnt base linux linux-firmware
}

# Generate the fstab
generate_fstab() {
	genfstab -U /mnt >> /mnt/etc/fstab
}

# Change root into installation, cloning the new chroot script
change_root() {

	# Clone the new script, move dependencies to installation,
	# execute script and delete it at the end
	curl "$CHROOT" > /mnt/chroot.sh
	mv ./*.sh /mnt
	arch-chroot /mnt bash chroot.sh
	rm /mnt/chroot.sh
}

# Set the time zone
set_time_zone() {
	ln -sf /usr/share/zoneinfo/"$1" /etc/localtime
	hwclock --systohc
}

# Uncomment locale from locale.gen
uncomment_locale() {
	sed -i "s/#${1}/${1}/g" /etc/locale.gen
}

# Export language variable
set_lang_var() {
	echo "LANG=${1}" > /etc/locale.conf

}

# Export keyboard layout variable
set_keyboard_var() {
	echo "KEYMAP=${keymap}" >> /etc/vconsole.conf
}

# Generate locales
generate_locales() {
	if [ "$country" = "Portugal" ]; then
		uncomment_locale "en_US.UTF-8"
		uncomment_locale "pt_PT.UTF-8"
		locale-gen && set_lang_var "en_US.UTF-8"
		set_keyboard_var "$keymap"
	fi
}

# Set hostname
set_hostname() {
	echo "$hostname" > /etc/hostname
}

# Create hosts file
set_hosts() {
cat <<EOF > /etc/hosts
127.0.0.1	localhost
::1			localhost
127.0.1.1	${hostname}.localdomain	${hostname}
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
	if ! [ "$crypt_passwd" = "" ]; then
		change_hooks "base systemd autodetect keyboard sd-vconsole modconf block sd-encrypt filesystems fsck"
	fi
}

# Changes all mkinitcpio hooks with the hooks given
change_hooks() {
	sed -i "s/HOOKS=.*/HOOKS=(${1})/g" /etc/mkinitcpio.conf
	create_initramfs
}

# Change systemd-boot default loader entry
change_default_entry() {
	sed -i "s/default.*/default\t${1}.conf/g" /boot/loader/loader.conf
}

# Create systemd-boot loader entry
create_loader_entry() {

	if [ "$crypt_passwd" = "" ]; then
cat <<EOF > /boot/loader/entries/arch.conf
title	Arch
linux	/vmlinuz-linux
initrd	/intel-ucode.img
initrd	/initramfs-linux-fallback.img
options root=${ROOT_PART} rw
EOF

	else
		UUID=$(blkid | grep "${ROOT_PART}" | awk {'print $2'} | awk -F '"' {'print $2'}) &&
cat <<EOF > /boot/loader/entries/arch.conf
title	Arch
linux	/vmlinuz-linux
initrd	/intel-ucode.img
initrd	/initramfs-linux-fallback.img
options rd.luks.name=${UUID}=cryptroot root=/dev/mapper/cryptroot rw
EOF
	fi
}

# Encrypt the root partition
encrypt_root() {

	# Encrypt the partition
	echo "$crypt_passwd" | cryptsetup -q luksFormat "$ROOT_PART"

	# Open the partition
	echo "$crypt_passwd" | cryptsetup open "$ROOT_PART" cryptroot
}

# Return the size of the given disk
get_disk_size() {

	# Variable with all disks and their sizes
	disk_sizes=$(lsblk -l | awk '/disk/ {print "/dev/"$1, $4}')

	# Get the size
	size=$(echo "$disk_sizes" | grep "$1" | awk '{print $2}')

	echo "$size"
}

# Return the size of the ram in MB
get_ram_size() {
	size=$(awk '/MemTotal/ {print $2}' "/proc/meminfo")
	size=$(( size / 1024 ))
	echo "$size"
}

# Change the value of the system swapiness while in installation media
change_system_swapiness() {
	echo "vm.swappiness=${1}" > /mnt/etc/sysctl.d/99-swappiness.conf
}

# Create a swap file and activates it while in installation media
create_swapfile() {

	# Swap is created with double RAM size
	size=$(( 2 * "$(get_ram_size)" ))

	# Create the swapfile and activate it
	dd if=/dev/zero of=/mnt/swapfile bs=1M count=${size} status=progress
	chmod 600 /mnt/swapfile
	mkswap /mnt/swapfile
	swapon /mnt/swapfile

	# Change system swapiness
	change_system_swapiness "10"
}

