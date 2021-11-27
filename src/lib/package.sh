#!/bin/bash
# Package management functions

################################################################################
# Synchronize pacman mirrors
################################################################################
sync_mirrors() {
	pacman -Syy
}

################################################################################
# Sort pacman mirrors by speed
# Arguments:
#     country
################################################################################
sort_mirrors() {
	install_silently "rsync" "reflector"
	reflector -c "$1" -a 6 --sort rate --save "/etc/pacman.d/mirrorlist"
	sync_mirrors
}

################################################################################
# Install a package or list of packages with pacman
# Arguments:
#     package(s)
################################################################################
install() {
	pacman -S $@ --noconfirm --needed
}

################################################################################
# Install a package or list of packages with pacman, silently
# Arguments:
#     package(s)
################################################################################
install_silently() {
	install $@ >/dev/null
}

################################################################################
# Install a package or list of packages with the AUR helper
# Arguments:
#     user
#     package(s)
################################################################################
install_aur() {
	user="$1"; shift
	sudo -u "$user" paru -S $@ --noconfirm --needed
}

################################################################################
# Install the AUR helper
# Arguments:
#     user
################################################################################
install_aur_helper() {
	install_paru "$1"
}

################################################################################
# Install the paru AUR helper
# Arguments:
#     user
################################################################################
install_paru() {

	# Install dependencies
	install "git"

	pushd /home/"$1"

	sudo -u "$1" git clone "https://aur.archlinux.org/paru-bin.git"
	pushd paru-bin
	sudo -u "$1" makepkg -si --noconfirm
	popd
	rm -rf paru-bin

	popd
}

################################################################################
# Install the essential packages with pacstrap
# Arguments:
#     package(s)
################################################################################
install_essential() {
	pacstrap /mnt $@
}

################################################################################
# Install packages through a package list file
# Arguments:
#     user
#     package file link
################################################################################
install_package_list() {
	install_aur "$1" "$(curl -sL "$2" | sed '/#.*$/d; /^[[:space:]]*$/d')"
}

################################################################################
# Configure the pacman package manager
################################################################################
pacman_configuration() {

	# Enable color and pacman visual
	grep -q "^Color" /etc/pacman.conf ||
		sed -i "s/^#Color$/Color/" /etc/pacman.conf
	grep -q "ILoveCandy" /etc/pacman.conf ||
		sed -i "/#VerbosePkgLists/a ILoveCandy" /etc/pacman.conf

	# Enable parallel downloads
	sed -i "s/^#ParallelDownloads = 5/ParallelDownloads = 5/" /etc/pacman.conf

	# Use all cores for compilation
	sed -i "s/-j2/-j$(nproc)/;s/^#MAKEFLAGS/MAKEFLAGS/" /etc/makepkg.conf
}
