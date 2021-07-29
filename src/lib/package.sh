#!/bin/bash
# Package management functions

################################################################################
# Sync pacman mirrors
################################################################################
sync_mirrors() {
	pacman -Syy
}

################################################################################
# Sort pacman mirrors based on speed
# Params:
#     country
################################################################################
update_mirrors() {
	reflector -c "$1" -a 6 --sort rate --save "/etc/pacman.d/mirrorlist"
	sync_mirrors
}

################################################################################
# Check if a package is installed pacman mirrors based on speed
# Params:
#     package
# Output:
#     boolean
################################################################################
is_installed() {
	pacman -Qnq | grep -q -wx "$1"
}

################################################################################
# Install a package or list of packages with pacman
# Params:
#     package(s)
################################################################################
install() {
	pacman -S $@ --noconfirm
}

################################################################################
# Install a package or list of packages with pacman, silently
# Params:
#     package(s)
################################################################################
install_silently() {
	install $@ >/dev/null
}

################################################################################
# Install a package or list of packages with the AUR helper
# Globals:
#     AUR_HELPER
# Params:
#     user
#     package(s)
################################################################################
install_aur() {
	user="$1"; shift
	sudo -u "$user" "$AUR_HELPER" -S $@ --noconfirm
}

################################################################################
# Install the paru AUR helper
# Params:
#     user
################################################################################
install_paru() {
	pushd /home/"$1"

	sudo -u "$1" git clone "https://aur.archlinux.org/paru-bin.git"
	pushd paru-bin
	sudo -u "$1" makepkg -si --noconfirm
	popd
	rm -rf paru-bin

	popd
}

################################################################################
# Install the yay AUR helper
# Params:
#     user
################################################################################
install_yay() {
	pushd /home/"$1"

	sudo -u "$1" git clone "https://aur.archlinux.org/yay-bin.git"
	pushd yay-bin
	sudo -u "$1" makepkg -si --noconfirm
	popd
	rm -rf yay-bin

	popd
}

################################################################################
# Install the AUR helper
# Globals:
#     AUR_HELPER
# Params:
#     user
################################################################################
install_aur_helper() {

	# Git is a dependency
	! is_installed "git" && install "git"

	case "$AUR_HELPER" in
		"paru") install_paru "$1" ;;
		"yay" ) install_yay "$1" ;;
	esac
}

################################################################################
# Install the essencial packages with pacstrap
# Params:
#     package(s)
################################################################################
install_essential() {
	pacstrap /mnt $@
}

################################################################################
# Install packages through a package list
# Params:
#     user
#     package file raw link
################################################################################
install_package_list() {
	install_aur "$1" "$(curl -sL "$2" | sed '/#.*$/d; /^[[:space:]]*$/d')"
}

################################################################################
# Add color and visuals to pacman and speed package compilation
################################################################################
pacman_configuration() {

	# Enable color and pacman visual
	grep -q "^Color" /etc/pacman.conf ||
		sed -i "s/^#Color$/Color/" /etc/pacman.conf
	grep -q "ILoveCandy" /etc/pacman.conf ||
		sed -i "/#VerbosePkgLists/a ILoveCandy" /etc/pacman.conf

	# Use all cores for compilation
	sed -i "s/-j2/-j$(nproc)/;s/^#MAKEFLAGS/MAKEFLAGS/" /etc/makepkg.conf
}
