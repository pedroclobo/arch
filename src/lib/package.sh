#!/bin/bash
# File with all package management functions

# Refresh pacman mirrors
refresh_mirrors() {
	pacman -Syy
}

# Sort pacman mirrors based on speed
# and location and refresh them
update_mirrors() {
	reflector -c "$1" -a 6 --sort rate --save "/etc/pacman.d/mirrorlist"
	refresh_mirrors
}

# Check if a package is installed
is_installed() {
	pacman -Qnq | grep -q -wx "$1"
}

# Install a package through pacman
install() {
	pacman -S "$@" --noconfirm
}

# Install essencial packages
install_essential() {
	pacstrap /mnt base linux linux-firmware
}

# Install video drivers
install_drivers() {
	if [ "$1" = "NVIDIA" ]; then
		install "nvidia" "nvidia-utils" "nvidia-settings"

	elif [ "$1" = "NVIDIA Optimus" ]; then
		install "xf86-video-intel" "nvidia" "nvidia-utils" "nvidia-settings" "nvidia-prime"

	elif [ "$1" = "AMD" ]; then
		install "xf86-video-amdgpu"

	elif [ "$1" = "Intel" ]; then
		install "xf86-video-intel"
	fi
}
