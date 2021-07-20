#!/bin/bash
# File with all system information related functions

# Check if the boot mode if UEFI
is_uefi_system() {
	[ -d "/sys/firmware/efi/efivars" ]
}

# Set keyboard layout
set_keymap() {
	loadkeys "$1"
}

# Update the system clock
update_clock() {
	timedatectl set-ntp true
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
set_timezone() {
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
set_keymap_var() {
	echo "KEYMAP=${keymap}" >> /etc/vconsole.conf
}

# Generate locales
generate_locales() {
	if [ "$country" = "Portugal" ]; then
		uncomment_locale "en_US.UTF-8"
		uncomment_locale "pt_PT.UTF-8"
		locale-gen && set_lang_var "en_US.UTF-8"
		set_keymap_var "$keymap"
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

# Return the size of the ram in MB
get_ram_size() {
	size=$(awk '/MemTotal/ {print $2}' "/proc/meminfo")
	size=$(( size / 1024 ))
	echo "$size"
}

# Change the value of the system swapiness
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
}

