#!/bin/bash
# User input related functions

# Source functions
source ./library.sh

# File to store the variables in
VAR_FILE="./variables.txt"

# String colors
RED='\033[0;31m'
NC='\033[0m'

# Prompt strings
MSG_CHOOSE_KEYBOARD="Enter your keyboard layout.\n(Type \"help\" to list all available keyboard layouts): "
MSG_INVALID_KEYBOARD="${RED}Invalid keyboard layout.${NC} Enter your keyboard layout: "
MSG_SELECT_COUNTRY="Enter your country (started by an upper case letter): "
MSG_SELECT_DISK="Choose the disk you want to install Linux to: "
MSG_INVALID_DISK="${RED}You have choosen an invalid disk.\n${NC} Please enter a valid one: "
MSG_CHOOSE_FS="Choose a filesystem to format your disk with: "
MSG_INVALID_FS="${RED}You have choosen an invalid filesystem.\n${NC} Please enter a valid one: "
MSG_ADD_CRYPT_PASSWD="Enter a password to encrypt the disk (Leave it blank if you don't want encryption): "
MSG_CONFIRM_PASSWD="Retype the password: "
MSG_PASSWD_NO_MATCH="${RED}Passwords do not match.\n${NC}Enter the password again: "
MSG_CHOOSE_HOSTNAME="Enter your desired hostname: "
MSG_ADD_PASSWD="Enter a password for the user: "
MSG_ADD_USER="Enter your desired username: "
MSG_INVALID_USER="${RED}Invalid username.\n${NC}Enter your desired username: "
MSG_CHOOSE_TIMEZONE="Enter your timezone.\n(Type \"help\" to list all available timezones): "
MSG_INVALID_TIMEZONE="${RED}Invalid timezone.\n${NC}Enter your timezone: "
MSG_REVIEW_CONFIGURATION="Please review the following configuration.\n"
MSG_CONFIRMATION="Do you want to proceed to the installation? (Y/n): "
MSG_START_INSTALL="${RED}There is no going back!\n${NC}Starting installation in"


# Write the variable to the variables file
export_variable() {
	echo "$1=\"$2\"" >> variables.txt
}

# Check if username is valid
is_valid_user() {
	printf "$1" | grep -q "^[a-z_][a-z0-9_-]*$"
}

# Prompt for keyboard layout
get_keyboard_layout() {

	# Prompt for keyboard layout
	printf "$MSG_CHOOSE_KEYBOARD" && read layout

	# Prompt again if entered keyboard layout is invalid
	# or list available keyboard layouts if "help" is typed
	while !(is_keyboard_layout "$layout"); do
		! [ "$layout" = "help" ] && printf "$MSG_INVALID_KEYBOARD" && read layout
		[ "$layout" = "help" ] && list_keyboard_layouts && printf "$MSG_CHOOSE_KEYBOARD" && read layout
	done

	# Export variable
	export_variable "KEY_LAYOUT" $layout && clear
}

# Prompt for location
get_country() {

	# Prompt for country
	printf "$MSG_SELECT_COUNTRY" && read country

	# Export variable
	export_variable "COUNTRY" $country && clear
}

# Prompt for disk to install OS to
get_disks() {

	# List disks and prompt for the installation disk
	list_disks
	printf "$MSG_SELECT_DISK" && read disk

	# Prompt again if entered disk is invalid
	while !(is_disk "$disk"); do
		printf "$MSG_INVALID_DISK" && read disk
	done

	# Export variable
	export_variable "DISK" $disk && clear
}

# Prompt for filesystem to format the disk with
get_filesystem() {

	# List available filesystems and prompt for a choice
	list_filesystems
	printf "$MSG_CHOOSE_FS" && read filesystem

	# Prompt again if entered filesystem isn't available
	while !(is_filesystem "$filesystem"); do
		printf "$MSG_INVALID_FS" && read filesystem
	done

	# Export variable
	export_variable "FILESYSTEM" $filesystem && clear
}

# Prompt for the encryption password
get_crypt_passwd() {

	# Prompt for password and its confirmation, silently
	printf "$MSG_ADD_CRYPT_PASSWD" && read -s pass1 && printf "\n"
	printf "$MSG_CONFIRM_PASSWD" && read -s pass2

	# If confirmation fails, prompt again for the password
	while ! [ "$pass1" = "$pass2" ]; do
		printf "\n"
		printf "$MSG_PASSWD_NO_MATCH" && read -s pass1 && printf "\n"
		printf "$MSG_CONFIRM_PASSWD" && read -s pass2
	done

	# Export variable
	export_variable "CRYPT_PASSWD" $pass1 && clear
}

# Prompt for hostname
get_hostname() {

	# Prompt for hostname
	printf "$MSG_CHOOSE_HOSTNAME" && read hostname

	# Export variable
	export_variable "HOSTNAME" $hostname && clear
}

# Prompt for root user password
get_passwd() {

	# Prompt for password and its confirmation, silently
	printf "$MSG_ADD_PASSWD" && read -s pass1 && printf "\n"
	printf "$MSG_CONFIRM_PASSWD" && read -s pass2

	# If confirmation fails, prompt again for the password
	while ! [ "$pass1" = "$pass2" ]; do
		printf "\n"
		printf "$MSG_PASSWD_NO_MATCH" && read -s pass1 && printf "\n"
		printf "$MSG_CONFIRM_PASSWD" && read -s pass2
	done

	# Export variable
	export_variable "PASSWD" $pass1 && clear
}

# Prompt for a user name
get_username() {

	# Prompt for user name
	printf "$MSG_ADD_USER" && read name

	# Prompt for new user name if it contains non-allowed characters
	while !(is_valid_user "$name"); do
		printf "$MSG_INVALID_USER" && read name
	done

	# Export variable
	export_variable "USER" $name && clear
}

# Prompt for timezone
get_timezone() {

	# List timezones and prompt for the timezone
	printf "$MSG_CHOOSE_TIMEZONE" && read timezone

	# Prompt again if entered timezone is invalid
	while !(is_timezone "$timezone"); do
		! [ "$timezone" = "help" ] && printf "$MSG_INVALID_TIMEZONE" && read timezone
		[ "$timezone" = "help" ] && list_timezones && printf "$MSG_CHOOSE_TIMEZONE" && read timezone
	done

	# Export variable
	export_variable "TIME_ZONE" $timezone && clear
}

# Prompt for confirmation
get_confirmation() {

	# Prompt the user to review the configuration
	printf "$MSG_REVIEW_CONFIGURATION" && printf "\n"

	# Print the configuration
	cat $VAR_FILE && printf "\n"

	# Ask for proceed confirmation
	printf "$MSG_CONFIRMATION" && read answer

	# If user declines, cancel installation
	[ "$answer" = "n" ] && exit

	# Else do the countdown
	[ "$answer" = "y" ] && printf "\n$MSG_START_INSTALL" && \
		for i in 5 4 3 2 1
		do
			printf " $i"
			sleep 1
		done
}
