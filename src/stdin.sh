#!/bin/bash
# User input related functions

# Source functions
source ./library.sh

# File to store the variables
VAR_FILE="./variables.csv"

# String colors
RED='\033[0;31m'
NC='\033[0m'

# Prompt strings
MSG_HELP_KEYMAP="(Type \"help\" or \"?\" to list all available keyboard layouts)."
MSG_CHOOSE_KEYMAP="Enter your keyboard layout (by number or full name): "
MSG_INVALID_KEYMAP="Invalid keyboard layout."
MSG_RETRY_KEYMAP="Please enter a valid keyboard layout: "
MSG_SEARCH_KEYMAP="Search for layout: "
MSG_CHOOSE_COUNTRY="Enter your country (by number or full name): "
MSG_INVALID_COUNTRY="Invalid country."
MSG_RETRY_COUNTRY="Please enter a valid country: "
MSG_CHOOSE_DISK="Choose the disk you want to install Linux to (by number or full name): "
MSG_INVALID_DISK="You have chosen an invalid disk."
MSG_RETRY_DISK="Please enter a valid disk: "
MSG_CHOOSE_FS="Choose a filesystem to format your disk with (by number or full name): "
MSG_INVALID_FS="You have choosen an invalid filesystem."
MSG_RETRY_FS="Please enter a valid filesystem: "
MSG_ADD_CRYPT_PASSWD="Enter a password to encrypt the disk (Leave it blank if you don't want encryption): "
MSG_CONFIRM_PASSWD="Retype the password: "
MSG_PASSWD_NO_MATCH="Passwords do not match."
MSG_RETRY_PASSWD="Please enter the password again: "
MSG_CHOOSE_HOSTNAME="Enter your desired hostname: "
MSG_ADD_PASSWD="Enter a password for the user: "
MSG_ADD_USER="Enter your desired username: "
MSG_INVALID_USER="Invalid username."
MSG_RETRY_USER="Please enter a valid username: "
MSG_HELP_TIMEZONE="(Type \"help\" or \"?\" to list all available timezones)."
MSG_CHOOSE_TIMEZONE="Enter your timezone (by number of full name): "
MSG_INVALID_TIMEZONE="Invalid timezone."
MSG_RETRY_TIMEZONE="Please enter a valid timezone: "
MSG_SEARCH_TIMEZONE="Search for timezone: "
MSG_REVIEW_CONFIGURATION="Please review the following configuration:"
MSG_CONFIRMATION="Do you want to proceed to the installation? (Y/n): "
MSG_START_INSTALL="There is no going back!"
MSG_COUNTDOWN_INSTALL="Starting installation in:"

# Arrays of accepted input
readarray -t keymaps <<< "$(localectl list-keymaps)"
countries=("Portugal")
readarray -t disks <<< "$(lsblk -l | awk '/disk/ {print "/dev/"$1""}')"
filesystems=("ext4")
readarray -t timezones <<< "$(timedatectl list-timezones)"

# Create the variable's file
create_varfile() {
	echo "#Variable,#Value" > "$VAR_FILE"
}

# Print the configuration file
print_varfile() {
	sed "/Password/d;/Encryption Password/d;s/,/: /g" "$VAR_FILE"
}

# Export variable to variable's file
export_variable() {
	echo "$1,\"$2\"" >> "$VAR_FILE"
}

# Returns the value of the specified variable
get_variable() {
	grep "$1" "$VAR_FILE" | awk -F ',' '{print $2}' | sed "s/\"//g"

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
		printf "%s: %s\n" "$i" "${keymaps["$i"]}"
	done
}

# Check if keymap is valid
is_valid_keymap() {

	# Keep track if element has been found
	in=1

	# Find element in array
	for keymap in "${keymaps[@]}"; do
		if [ "$keymap" == "$1" ]; then
			in=0 && break
		fi
	done

	# Returns 0 if the element is found
	return "$in"
}

# List all available countries
list_countries() {
	for (( i = 0; i < ${#countries[@]}; i++ )); do
		printf "%s: %s\n" "$i" "${countries["$i"]}"
	done
}


# Check if country is valid
is_valid_country() {

	# Keep track if element has been found
	in=1

	# Find element in array
	for country in "${countries[@]}"; do
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
		printf "%s: %s (%s)\n" "$i" "$disk" "$size"
	done
}

# Check if disk is valid
is_valid_disk() {

	# Keep track if element has been found
	in=1

	# Find element in array
	for disk in "${disks[@]}"; do
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
		printf "%s: %s\n" "$i" "${filesystems["$i"]}"
	done
}


# Check if filesystem is supported
is_valid_filesystem() {

	# Keep track if element has been found
	in=1

	# Find element in array
	for fs in "${filesystems[@]}"; do
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
		printf "%s: %s\n" "$i" "${timezones["$i"]}"
	done
}

# Check if timezone is valid
is_valid_timezone() {

	# Keep track if element has been found
	in=1

	# Find element in array
	for timezone in "${timezones[@]}"; do
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
prompt_keymap() {

	# Prompt for keymap
	printf "%s\n%s" "$MSG_HELP_KEYMAP" "$MSG_CHOOSE_KEYMAP" && read -r keymap

	# While an invalid keymap is introduced, prompt for a new input
	while ! (is_valid_keymap "$keymap"); do

		# If help is triggered, do a grep search
		if is_help_string "$keymap"; then
			printf "%s" "$MSG_SEARCH_KEYMAP" && read -r search
			list_keymaps | grep -i "$search"
			printf "%s" "$MSG_CHOOSE_KEYMAP" && read -r keymap

			# Case the input is a list index
			if is_number "$keymap"; then
				keymap=${keymaps["$keymap"]}
			fi

		# Invalid keymap message and prompt for a new input
		else
			printf "${RED}%s${NC} %s" "$MSG_INVALID_KEYMAP" "$MSG_RETRY_KEYMAP" && read -r keymap

			# Case the input is a list index
			if is_number "$keymap"; then
				keymap=${keymaps["$keymap"]}
			fi
		fi

	done

	# Export variable
	export_variable "Keyboard Layout" "$keymap" && clear
}

# Prompt for location
prompt_country() {

	# List all countries
	list_countries

	# Prompt for country
	printf "%s" "$MSG_CHOOSE_COUNTRY" && read -r country

	# While an invalid country is introduced, prompt for a new input
	while ! (is_valid_country "$country"); do

		# Case the input is a list index
		if is_number "$country"; then
			country=${countries["$country"]}

		# Invalid country message and prompt for a new input
		else
			printf "${RED}%s${NC} %s" "$MSG_INVALID_COUNTRY" "$MSG_RETRY_COUNTRY" && read -r country
		fi

	done

	# Export variable
	export_variable "Country" "$country" && clear
}

# Prompt for disk to install OS to
prompt_disk() {

	# List all disks ready for format
	list_disks

	# Prompt for disk
	printf "%s" "$MSG_CHOOSE_DISK" && read -r disk

	# While an invalid disk is introduced, prompt for a new input
	while ! (is_valid_disk "$disk"); do

		# Case the input is a list index
		if is_number "$disk"; then
			disk=${disks["$disk"]}

		# Invalid disk message and prompt for a new input
		else
			printf "${RED}%s${NC} %s" "$MSG_INVALID_DISK" "$MSG_RETRY_DISK" && read -r disk
		fi

	done

	# Export variable
	export_variable "Disk" "$disk" && clear
}

# Prompt for filesystem to format the disk with
prompt_filesystem() {

	# List all filesystems supported
	list_filesystems

	# Prompt for country
	printf "%s" "$MSG_CHOOSE_FS" && read -r fs

	# While an invalid country is introduced, prompt for a new input
	while ! (is_valid_filesystem "$fs"); do

		# Case the input is a list index
		if is_number "$fs"; then
			fs=${filesystems["$fs"]}

		# Invalid country message and prompt for a new input
		else
			printf "${RED}%s${NC} %s" "$MSG_INVALID_FS" "$MSG_RETRY_FS" && read -r fs
		fi

	done

	# Export variable
	export_variable "Filesystem" "$fs" && clear
}

# Prompt for the encryption password
prompt_crypt_passwd() {

	# Prompt for password and its confirmation, silently
	printf "%s" "$MSG_ADD_CRYPT_PASSWD" && read -r -s pass1 && printf "\n"
	printf "%s" "$MSG_CONFIRM_PASSWD" && read -r -s pass2

	# If confirmation fails, prompt again for the password
	while ! [ "$pass1" = "$pass2" ]; do
		printf "\n"
		printf "${RED}%s${NC} %s" "$MSG_PASSWD_NO_MATCH" "$MSG_RETRY_PASSWD" && read -r -s pass1 && printf "\n"
		printf "%s" "$MSG_CONFIRM_PASSWD" && read -r -s pass2
	done

	# Export variable
	export_variable "Encryption Password" "$pass1" && clear
}

# Prompt for hostname
prompt_hostname() {

	# Prompt for hostname
	printf "%s" "$MSG_CHOOSE_HOSTNAME" && read -r hostname

	# Export variable
	export_variable "Hostname" "$hostname" && clear
}

# Prompt for root user password
prompt_passwd() {

	# Prompt for password and its confirmation, silently
	printf "%s" "$MSG_ADD_PASSWD" && read -r -s pass1 && printf "\n"
	printf "%s" "$MSG_CONFIRM_PASSWD" && read -r -s pass2

	# If confirmation fails, prompt again for the password
	while ! [ "$pass1" = "$pass2" ]; do
		printf "\n"
		printf "${RED}%s${NC} %s" "$MSG_PASSWD_NO_MATCH" "$MSG_RETRY_PASSWD" && read -r -s pass1 && printf "\n"
		printf "%s" "$MSG_CONFIRM_PASSWD" && read -r -s pass2
	done

	# Export variable
	export_variable "Password" "$pass1" && clear
}

# Prompt for a user name
prompt_username() {

	# Prompt for user name
	printf "%s" "$MSG_ADD_USER" && read -r name

	# Prompt for new user name if it contains non-allowed characters
	while ! (is_valid_user "$name"); do
		printf "${RED}%s${NC} %s" "$MSG_INVALID_USER" "$MSG_RETRY_USER" && read -r name
	done

	# Export variable
	export_variable "User" "$name" && clear
}

# Prompt for timezone
prompt_timezone() {

	# Prompt for timezone
	printf "%s\n%s" "$MSG_HELP_TIMEZONE" "$MSG_CHOOSE_TIMEZONE" && read -r timezone

	# While an invalid timezone is introduced, prompt for a new input
	while ! (is_valid_timezone "$timezone"); do

		# If help is triggered, do a grep search
		if is_help_string "$timezone"; then
			printf "%s" "$MSG_SEARCH_TIMEZONE" && read -r search
			list_timezones | grep -i "$search"
			printf "%s" "$MSG_CHOOSE_TIMEZONE" && read -r timezone

			# Case the input is a list index
			if is_number "$timezone"; then
				timezone=${timezones["$timezone"]}
			fi

		# Invalid timezone message and prompt for a new input
		else
			printf "${RED}%s${NC} %s" "$MSG_INVALID_TIMEZONE" "$MSG_RETRY_TIMEZONE" && read -r timezone

			# Case the input is a list index
			if is_number "$timezone"; then
				timezone=${timezones["$timezone"]}
			fi
		fi

	done

	# Export variable
	export_variable "Time Zone" "$timezone" && clear
}

# Prompt for confirmation
prompt_confirmation() {

	# Prompt the user to review the configuration
	printf "%s\n\n" "$MSG_REVIEW_CONFIGURATION"

	# Print the configuration
	print_varfile && print "\n"

	# Ask for proceed confirmation
	printf "%s" "$MSG_CONFIRMATION" && read -r answer

	# If user declines, cancel installation
	[ "$answer" = "n" ] && exit

	# Else, do the countdown
	[ "$answer" = "y" ] && printf "\n\n%s\n%s" "$MSG_START_INSTALL" "$MSG_COUNTDOWN_INSTALL" && \
		for i in 5 4 3 2 1
		do
			printf " %s" "$i"
			sleep 1
		done
	clear
}

# Return the chosen keymap
get_keymap() {
	get_variable "Keyboard Layout"
}

# Return the chosen country
get_country() {
	get_variable "Country"
}

# Return the chosen disk
get_disk() {
	get_variable "Disk"
}

# Return the chosen filesystem
get_filesystem() {
	get_variable "Filesystem"
}

# Return the chosen encryption password
get_cryptpasswd() {
	get_variable "Encryption Password"
}

# Return the chosen password
get_passwd() {
	get_variable "Password"
}

# Return the chosen time zone
get_timezone() {
	get_variable "Time Zone"
}
