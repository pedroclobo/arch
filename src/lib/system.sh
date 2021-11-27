#!/bin/bash
# System information functions

################################################################################
# Check if the boot mode if UEFI
# Returns:
#     0 if system is in UEFI mode, 1 if not
################################################################################
is_uefi_system() {
	[ -d "/sys/firmware/efi/efivars" ]
}

################################################################################
# Return the size of RAM in MB
# Returns:
#     size of RAM in MB
################################################################################
get_ram_size() {
	size=$(awk '/MemTotal/ {print $2}' "/proc/meminfo")
	size=$(( size / 1024 ))
	echo "$size"
}

################################################################################
# Get the CPU brand
# Returns:
#     CPU brand
################################################################################
get_cpu_brand() {
	if grep -q 'Intel' /proc/cpuinfo; then
		echo "Intel"
	elif grep -q 'AMD' /proc/cpuinfo; then
		echo "AMD"
	fi
}

################################################################################
# Load the keyboard layout
# Arguments:
#     keyboard layout
################################################################################
load_keymap() {
	loadkeys "$1"
}

################################################################################
# Set the KEYMAP variable
# Arguments:
#     keymap
################################################################################
set_keymap() {
	echo "KEYMAP=${1}" >> /etc/vconsole.conf
}

################################################################################
# Update the system clock
################################################################################
update_clock() {
	timedatectl set-ntp true
}

################################################################################
# Set the time zone the system clock
# Arguments:
#     timezone
################################################################################
set_timezone() {
	ln -sf /usr/share/zoneinfo/"$1" /etc/localtime
	hwclock --systohc
}

################################################################################
# Uncomment locale from locale.gen
# Arguments:
#     locale
################################################################################
uncomment_locale() {
	sed -i "s/#${1}/${1}/g" /etc/locale.gen
}

################################################################################
# Set LANG variable
# Arguments:
#     language
################################################################################
set_lang() {
	echo "LANG=${1}" > /etc/locale.conf
}

################################################################################
# Set hostname
# Arguments:
#     hostname
################################################################################
set_hostname() {
	echo "$1" > /etc/hostname
}

################################################################################
# Add entries to hosts file
# Arguments:
#     hostname
################################################################################
add_hosts() {
cat <<EOF > /etc/hosts
127.0.0.1	localhost
::1			localhost
127.0.1.1	${1}.localdomain	${1}
EOF
}

################################################################################
# Generate locales
# Arguments:
#     country
#     keyboard layout
################################################################################
generate_locales() {
	case "$1" in
		"Portugal")
			uncomment_locale "en_US.UTF-8"
			uncomment_locale "pt_PT.UTF-8"
			locale-gen && set_lang "en_US.UTF-8"
			set_keymap "$2" ;;
	esac
}

################################################################################
# Generate the fstab
################################################################################
generate_fstab() {
	genfstab -U /mnt >> /mnt/etc/fstab
}

################################################################################
# Change root into installation and run the new script, deleting files after
# Arguments:
#     raw chroot script link
################################################################################
change_root() {
	curl "$1" > /mnt/chroot.sh
	mv ./* /mnt
	arch-chroot /mnt bash chroot.sh

	# Delete all files after chroot has finished
	rm /mnt/*.sh
}

################################################################################
# Uncomment the given line in the sudoers file
# Arguments:
#     sudoers file line
################################################################################
sudoers_uncomment() {
	grep -q "^${1}" /etc/sudoers || sed -i "s/^# ${1}/${1}/g" /etc/sudoers
}

################################################################################
# Comment the given line in the sudoers file
# Arguments:
#     sudoers file line
################################################################################
sudoers_comment() {
	grep -q "^# ${1}" /etc/sudoers || sed -i "s/^${1}/# ${1}/g" /etc/sudoers
}

################################################################################
# Set the /bin/sh shell
# Arguments:
#     shell name
################################################################################
set_shell() {
	install "$1"
	ln -sfT "$1" /usr/bin/sh
}

################################################################################
# Change the value of the system swapiness
# Arguments:
#     system swapiness value
################################################################################
change_system_swapiness() {
	echo "vm.swappiness=${1}" > /mnt/etc/sysctl.d/99-swappiness.conf
}

################################################################################
# Enable periodic TRIM for SSD's
################################################################################
enable_trim() {
	systemctl enable fstrim.timer
}

################################################################################
# Install CPU microcode
################################################################################
install_microcode() {
	brand=$(get_cpu_brand)

	case "$brand" in
		"Intel") install_microcode_intel ;;
		"AMD") install_microcode_amd ;;
	esac
}

################################################################################
# Install Intel CPU microcode
################################################################################
install_microcode_intel() {
	install "intel-ucode"
}

################################################################################
# Install AMD CPU microcode
################################################################################
install_microcode_amd() {
	install "amd-ucode"
}

################################################################################
# Create initramfs
################################################################################
create_initramfs() {
	mkinitcpio -P
}

################################################################################
# Replace mkinitcpio hook
# Arguments:
#     hook to replace
#     replacement hook
################################################################################
replace_hook() {
	sed -i "s/${1}/${2}/g" /etc/mkinitcpio.conf
	create_initramfs
}

################################################################################
# Change mkinitcpio hooks
# Arguments:
#     string with all hooks
################################################################################
change_hooks() {
	sed -i "s/^HOOKS=.*/HOOKS=(${1})/g" /etc/mkinitcpio.conf
	create_initramfs
}

################################################################################
# Install the bootloader
# Arguments:
#     disk
#     encryption password
################################################################################
install_bootloader() {
	if is_uefi_system; then
		install_systemd_boot "$2"
	else
		install_grub "$1" "$2"
	fi
}

################################################################################
# Create a systemdboot loader entry
################################################################################
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

################################################################################
# Change systemdboot default loader entry
# Arguments:
#     entry name
################################################################################
change_default_entry() {
	sed -i "s/default.*/default\t${1}.conf/g" /boot/loader/loader.conf
}

################################################################################
# Install systemdboot for non-encrypted and encrypted systems
# Arguments:
#     crypt_passwd
################################################################################
install_systemd_boot() {

	bootctl --path=/boot install

	create_loader_entry
	change_default_entry "arch"

	# Change hooks if encryption is choosen
	case "$1" in
		*) change_hooks "base systemd autodetect keyboard sd-vconsole modconf block sd-encrypt filesystems fsck" ;;
	esac
}

################################################################################
# Modify the grub configuration
# Globals:
#     ROOT_PART
################################################################################
modify_grub_cfg() {
	sed -i "s|^GRUB_CMDLINE_LINUX=.*|GRUB_CMDLINE_LINUX=\"cryptdevice=${ROOT_PART}:cryptroot\"|" /etc/default/grub
}

################################################################################
# Install GRUB bootloader for non-encrypted and encrypted systems
# Globals:
#     ROOT_PART
# Arguments:
#     disk
#     encryption password
################################################################################
install_grub() {

	install "grub"

	case "$2" in
		*) modify_grub_cfg
		   change_hooks "base udev autodetect modconf block encrypt filesystems keyboard fsck" ;;
	esac

	grub-install --target=i386-pc "$disk"
	grub-mkconfig -o /boot/grub/grub.cfg
}

################################################################################
# Setup silent boot
# Arguments:
#     user
################################################################################
silent_boot() {

	# Remove last login message
	pushd /home/"$1"
	sudo -u "$1" touch .hushlogin
	popd

	# Enable auto-login
	mkdir -p /etc/systemd/system/getty@tty1.service.d
cat <<EOF > /etc/systemd/system/getty@tty1.service.d/skip-prompt.conf
[Service]
ExecStart=
ExecStart=-/usr/bin/agetty --skip-login --nonewline --noissue --autologin $1 --noclear %I \$TERM
EOF

}

################################################################################
# Add user
# Arguments:
#     user
#     password
#     shell
################################################################################
add_user() {
	install "$3"
	useradd -m -G "wheel,audio,video,optical,storage" -s "/bin/${3}" "$1"
	set_password "$1" "$2"
}

################################################################################
# Set password for the user
# Arguments:
#     user
#     password
################################################################################
set_password() {
	echo "${1}:${2}" | chpasswd
}

################################################################################
# Change user default shell
# Arguments:
#     user
#     shell
################################################################################
change_user_sh() {
	usermod --shell "/bin/${2}" "$1"
}

################################################################################
# Install NVIDIA display drivers
################################################################################
install_driver_nvidia() {
	install "nvidia" "nvidia-utils" "nvidia-settings"
}

################################################################################
# Install Intel display drivers
################################################################################
install_driver_intel() {
	install "xf86-video-intel"
}

################################################################################
# Install NVIDIA display drivers with Optimus support
# Arguments:
#     user
################################################################################
install_driver_optimus() {
	install_driver_intel
	install_driver_nvidia

	install_aur "$1" "system76-power"
	systemctl enable --now system76-power.service
	system76-power graphics integrated
}

################################################################################
# Install AMD display drivers
################################################################################
install_driver_amd() {
	install "xf86-video-amdgpu"
}

################################################################################
# Install display drivers
# Arguments:
#     display driver
#     user
################################################################################
install_drivers() {
	case "$1" in
		"NVIDIA")
			install_driver_nvidia ;;
		"NVIDIA Optimus")
			install_driver_optimus "$2" ;;
		"AMD")
			install_driver_amd ;;
		"Intel")
			install_driver_intel ;;
	esac
}

################################################################################
# Install the Xorg display server
################################################################################
install_xorg() {
	install "xorg" "xorg-xinit"
}

################################################################################
# Install the Xorg display server
# Arguments:
#     display server
################################################################################
install_display_server() {
	case "$1" in
		"Xorg") install_xorg ;;
	esac
}

################################################################################
# Install the desktop environment / window manager
# Arguments:
#     desktop environment / window manager
#     user
#     package list
################################################################################
install_desktop() {
	case "$1" in
		"dwm (laptop)")
			install_dwm "$2" "laptop"
			install_package_list "$2" "$3" ;;
		"dwm (desktop)")
			install_dwm "$2" "desktop"
			install_package_list "$2" "$3" ;;
		"Gnome")
			install_gnome ;;
	esac
}

################################################################################
# Install the dwm window manager and deploys all related dotfiles
# Arguments:
#     user
#     type of install
################################################################################
install_dwm() {

	# Install dependencies
	install "stow" "git" "zsh"

	# Clone dotfiles repository
	pushd /home/"$1"
	sudo -u "$1" git clone --branch "$2" --recurse-submodules https://github.com/pedroclobo/dotfiles.git repos/dotfiles

	# Stow all dotfiles
	pushd repos/dotfiles
	ls -d */ | xargs stow -t /home/"$1"

	# Compile suckless programs
	for program in $(ls suckless/.config); do
		pushd suckless/.config/"$program"
		make clean install
		popd
	done

	popd
	popd

	# Change user default shell
	change_user_sh "$1" "zsh"

	# Users can execute sudo commands without being prompted for a password
	sudoers_uncomment "%wheel ALL=(ALL) NOPASSWD: ALL"

	# Setup silent boot
	silent_boot "$1"

}

################################################################################
# Install the gnome desktop environment
################################################################################
install_gnome() {
	install "gnome"
	systemctl enable gdm
	sed -i "s/#WaylandEnable=false/WaylandEnable=false/g" /etc/gdm/custom.conf
}

################################################################################
# Finish installation
# Arguments:
#     desktop
################################################################################
finalize() {
	case "$1" in
		"dwm (laptop)"|"dwm (desktop)")
			finalize_dwm ;;
		"Gnome")
			finalize_gnome ;;
	esac
}

################################################################################
# Finish installation for the dwm desktop
################################################################################
finalize_dwm() {
	true
}

################################################################################
# Finish installation for the GNOME desktop
################################################################################
finalize_gnome() {

	# Users must enter their password to run sudo commands
	sudoers_comment "%wheel ALL=(ALL) NOPASSWD: ALL"
}
