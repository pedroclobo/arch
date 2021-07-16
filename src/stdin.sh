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
MSG_CHOOSE_KEYMAP="Enter your keyboard layout (by number or full name).\n(Type \"help\" or \"?\" to list all available keyboard layouts): "
MSG_INVALID_KEYMAP="${RED}Invalid keyboard layout.${NC} Please enter a valid keyboard layout: "
MSG_SEARCH_KEYMAP="Search for layout: "
MSG_CHOOSE_COUNTRY="Enter your country (by number or full name): "
MSG_INVALID_COUNTRY="${RED}Invalid country.${NC} Please enter a valid country: "
MSG_CHOOSE_DISK="Choose the disk you want to install Linux to (by number or full name): "
MSG_INVALID_DISK="${RED}You have chosen an invalid disk.\n${NC}Please enter a valid one: "
MSG_CHOOSE_FS="Choose a filesystem to format your disk with (by number or full name): "
MSG_INVALID_FS="${RED}You have choosen an invalid filesystem.\n${NC}Please enter a valid one: "
MSG_ADD_CRYPT_PASSWD="Enter a password to encrypt the disk (Leave it blank if you don't want encryption): "
MSG_CONFIRM_PASSWD="Retype the password: "
MSG_PASSWD_NO_MATCH="${RED}Passwords do not match.\n${NC}Enter the password again: "
MSG_CHOOSE_HOSTNAME="Enter your desired hostname: "
MSG_ADD_PASSWD="Enter a password for the user: "
MSG_ADD_USER="Enter your desired username: "
MSG_INVALID_USER="${RED}Invalid username.\n${NC}Enter your desired username: "
MSG_CHOOSE_TIMEZONE="Enter your timezone (by number of full name).\n(Type \"help\" or \"?\" to list all available timezones): "
MSG_INVALID_TIMEZONE="${RED}Invalid timezone.\n${NC}Please enter a valid timezone: "
MSG_SEARCH_TIMEZONE="Search for timezone: "
MSG_REVIEW_CONFIGURATION="Please review the following configuration:\n"
MSG_CONFIRMATION="Do you want to proceed to the installation? (Y/n): "
MSG_START_INSTALL="${RED}There is no going back!\n\n${NC}Starting installation in"

# Arrays of accepted input
keymaps=($(localectl list-keymaps))
countries=("Portugal")
disks=($(lsblk -l | awk '/disk/ {print "/dev/"$1""}'))
filesystems=("ext4")
timezones=($(timedatectl list-timezones))


# Write the variable to the variable's file
export_variable() {
	echo "$1=\"$2\"" >> "$VAR_FILE"
	source "$VAR_FILE"
}

# Print the configuration file
print_varfile() {
	sed "/PASSWD/d;/CRYPT_PASSWD/d" "$VAR_FILE"
}

# Check if input is a number
is_number() {
	case "$1" in
	    ''|*[!0-9]*) return 1 ;;
	    *) return 0 ;;
	esac
}

# Check if input is the help input
is_help_string() {
	case $1 in
		"help"|"?") return 0 ;;
		*) return 1;;
	esac
}

# List all available keymaps
list_keymaps() {
	for (( i = 0; i < ${#keymaps[@]}; i++ )); do
		echo "$i": ${keymaps["$i"]}
	done
}

# Check if keymap is valid
is_valid_keymap() {

	# Keep track if element has been found
	in=1

	# Find element in array
	for keymap in ${keymaps[@]}; do
		if [[ "$keymap" == "$1" ]]; then
			in=0 && break
		fi
	done

	# Returns 0 if the element is found
	return "$in"
}

# List all available countries
list_countries() {
	for (( i = 0; i < ${#countries[@]}; i++ )); do
		echo "$i": ${countries["$i"]}
	done
}


# Check if country is valid
is_valid_country() {

	# Keep track if element has been found
	in=1

	# Find element in array
	for country in ${countries[@]}; do
		if [[ "$country" == "$1" ]]; then
			in=0 && break
		fi
	done

	# Returns 0 if the element is found
	return "$in"
}

# List all available countries
list_disks() {

	# List disk followed by disk size
	for (( i = 0; i < ${#disks[@]}; i++ )); do
		disk=${disks["$i"]}
		size=$(get_disk_size "$disk")
		echo "$i": $disk "("$size")"
	done
}

# Check if disk is valid
is_valid_disk() {

	# Keep track if element has been found
	in=1

	# Find element in array
	for disk in ${disks[@]}; do
		if [[ "$disk" == "$1" ]]; then
			in=0 && break
		fi
	done

	# Returns 0 if the element is found
	return "$in"
}

# List all available filesystems
list_filesystems() {
	for (( i = 0; i < ${#filesystems[@]}; i++ )); do
		echo "$i": ${filesystems["$i"]}
	done
}


# Check if filesystem is supported
is_valid_filesystem() {

	# Keep track if element has been found
	in=1

	# Find element in array
	for fs in ${filesystems[@]}; do
		if [[ "$fs" == "$1" ]]; then
			in=0 && break
		fi
	done

	# Returns 0 if the element is found
	return "$in"
}

# List all available timezones
list_timezones() {
	for (( i = 0; i < ${#timezones[@]}; i++ )); do
		echo "$i": ${timezones["$i"]}
	done
}

# Check if timezone is valid
is_valid_timezone() {

	# Keep track if element has been found
	in=1

	# Find element in array
	for timezone in ${timezones[@]}; do
		if [[ "$timezone" == "$1" ]]; then
			in=0 && break
		fi
	done

	# Returns 0 if the element is found
	return "$in"
}

# Check if username is valid
is_valid_user() {
	echo "$1" | grep -q "^[a-z_][a-z0-9_-]*$"
}


# Prompt for keymap
get_keymap() {

	# Prompt for keymap
	printf "$MSG_CHOOSE_KEYMAP" && read keymap

	# While an invalid keymap is introduced, prompt for a new input
	while !(is_valid_keymap "$keymap"); do

		# If help is triggered, do a grep search
		if is_help_string "$keymap"; then
			printf "$MSG_SEARCH_KEYMAP" && read search
			list_keymaps | grep -i "$search"
			printf "$MSG_CHOOSE_KEYMAP" && read keymap

			# Case the input is a list index
			if is_number "$keymap"; then
				keymap=${keymaps["$keymap"]}
			fi

		# Invalid keymap message and prompt for a new input
		else
			printf "$MSG_INVALID_KEYMAP" && read keymap
		fi

	done

	# Export variable
	export_variable "KEYMAP" $keymap && clear
}

# Prompt for location
get_country() {

	# List all countries
	list_countries

	# Prompt for country
	printf "$MSG_CHOOSE_COUNTRY" && read country

	# While an invalid country is introduced, prompt for a new input
	while !(is_valid_country "$country"); do

		# Case the input is a list index
		if is_number "$country"; then
			country=${countries["$country"]}

		# Invalid country message and prompt for a new input
		else
			printf "$MSG_INVALID_COUNTRY" && read country
		fi

	done

	# Export variable
	export_variable "COUNTRY" $country && clear
}

# Prompt for disk to install OS to
get_disk() {

	# List all disks ready for format
	list_disks

	# Prompt for disk
	printf "$MSG_CHOOSE_DISK" && read disk

	# While an invalid disk is introduced, prompt for a new input
	while !(is_valid_disk "$disk"); do

		# Case the input is a list index
		if is_number "$disk"; then
			disk=${disks["$disk"]}

		# Invalid disk message and prompt for a new input
		else
			printf "$MSG_INVALID_DISK" && read disk
		fi

	done

	# Export variable
	export_variable "DISK" $disk && clear
}

# Prompt for filesystem to format the disk with
get_filesystem() {

	# List all filesystems supported
	list_filesystems

	# Prompt for country
	printf "$MSG_CHOOSE_FS" && read fs

	# While an invalid country is introduced, prompt for a new input
	while !(is_valid_filesystem "$fs"); do

		# Case the input is a list index
		if is_number "$fs"; then
			fs=${filesystems["$fs"]}

		# Invalid country message and prompt for a new input
		else
			printf "$MSG_INVALID_FS" && read fs
		fi

	done

	# Export variable
	export_variable "FILESYSTEM" $fs && clear
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

	# Prompt for timezone
	printf "$MSG_CHOOSE_TIMEZONE" && read timezone

	# While an invalid timezone is introduced, prompt for a new input
	while !(is_valid_timezone "$timezone"); do

		# If help is triggered, do a grep search
		if is_help_string "$timezone"; then
			printf "$MSG_SEARCH_TIMEZONE" && read search
			list_timezones | grep -i "$search"
			printf "$MSG_CHOOSE_TIMEZONE" && read timezone

			# Case the input is a list index
			if is_number "$timezone"; then
				timezone=${timezones["$timezone"]}
			fi

		# Invalid timezone message and prompt for a new input
		else
			printf "$MSG_INVALID_TIMEZONE" && read timezone
		fi

	done

	# Export variable
	export_variable "TIME_ZONE" $timezone && clear
}

# Prompt for confirmation
get_confirmation() {

	# Prompt the user to review the configuration
	printf "$MSG_REVIEW_CONFIGURATION" && printf "\n"

	# Print the configuration
	print_varfile && printf "\n"

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
	clear
}
