#!/bin/bash
# User input functions

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
MSG_CHOOSE_DRIVER="Choose a video driver to install (by number or full name): "
MSG_INVALID_DRIVER="You have choosen an invalid video driver."
MSG_RETRY_DRIVER="Please enter a valid video driver: "
MSG_CHOOSE_DESKTOP="Choose a desktop environment to install (by number or full name): "
MSG_INVALID_DESKTOP="You have choosen an invalid desktop environment."
MSG_RETRY_DESKTOP="Please enter a valid desktop environment: "
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
drivers=("None" "NVIDIA" "NVIDIA Optimus" "AMD" "Intel")
desktops=("Gnome" "dwm")

# String colors
RED='\033[0;31m'
NC='\033[0m'


################################################################################
# Print the user configuration
# Globals:
#     keymap
#     country
#     disk
#     filesystem
#     hostname
#     timezone
#     driver
#     user
#     desktop
# Outputs:
#     "variable": "value"
################################################################################
print_configuration() {

	declare -A variables=(
		["Keyboard Layout"]="$keymap"
		["Country"]="$country"
		["Disk"]="$disk"
		["Filesystem"]="$filesystem"
		["Hostname"]="$hostname"
		["Time Zone"]="$timezone"
		["Drivers"]="$driver"
		["User"]="$user"
		["Desktop"]="$desktop"
	)

	for name in "${!variables[@]}"; do
		printf "%s: %s\n" "$name" "${variables["$name"]}"
	done
}

################################################################################
# Check if input is a number
# Arguments:
#     any
# Returns:
#     0 if is a number, 1 if not
################################################################################
is_number() {
	case "$1" in
	    ""|*[!0-9]*) return 1 ;;
	    *) return 0 ;;
	esac
}

################################################################################
# Check if input is any help string
# Arguments:
#     any
# Returns:
#     0 if is a help string, 1 if not
################################################################################
is_help_string() {
	case $1 in
		"help"|"?") return 0 ;;
		*) return 1;;
	esac
}

################################################################################
# List all available keymaps
# Globals:
#     keymaps
# Outputs:
#     "index": "keymap"
################################################################################
list_keymaps() {
	for (( i = 0; i < ${#keymaps[@]}; i++ )); do
		printf "%s: %s\n" "$i" "${keymaps["$i"]}"
	done
}

################################################################################
# Check if keymap is valid
# Globals:
#     keymaps
# Arguments:
#     string
# Returns:
#     0 if is a valid keymap, 1 if not
################################################################################
is_valid_keymap() {
	for keymap in "${keymaps[@]}"; do
		[[ "$keymap" == "$1" ]] && return 0
	done

	return 1
}

################################################################################
# List all available countries
# Globals:
#     countries
# Outputs:
#     "index": "country"
################################################################################
list_countries() {
	for (( i = 0; i < ${#countries[@]}; i++ )); do
		printf "%s: %s\n" "$i" "${countries["$i"]}"
	done
}


################################################################################
# Check if country is valid
# Globals:
#     countries
# Arguments:
#     string
# Returns:
#     0 if is a valid country, 1 if not
################################################################################
is_valid_country() {
	for country in "${countries[@]}"; do
		[[ "$country" == "$1" ]] && return 0
	done

	return 1
}

################################################################################
# List all available disks
# Globals:
#     disks
# Outputs:
#     "index": "disk" ("size")
################################################################################
list_disks() {
	for (( i = 0; i < ${#disks[@]}; i++ )); do
		disk=${disks["$i"]}
		size=$(get_disk_size "$disk")
		printf "%s: %s (%s)\n" "$i" "$disk" "$size"
	done
}

################################################################################
# Check if disk is valid
# Globals:
#     disks
# Arguments:
#     string
# Returns:
#     0 if is a valid disk, 1 if not
################################################################################
is_valid_disk() {
	for disk in "${disks[@]}"; do
		[[ "$disk" == "$1" ]] && return 0
	done

	return 1
}

################################################################################
# List all available filesystems
# Globals:
#     filesystems
# Outputs:
#     "index": "filesystem"
################################################################################
list_filesystems() {
	for (( i = 0; i < ${#filesystems[@]}; i++ )); do
		printf "%s: %s\n" "$i" "${filesystems["$i"]}"
	done
}


################################################################################
# Check if filesystem is supported
# Globals:
#     filesystems
# Arguments:
#     string
# Returns:
#     0 if is a supported filesystem, 1 if not
################################################################################
is_valid_filesystem() {
	for fs in "${filesystems[@]}"; do
		[[ "$fs" == "$1" ]] && return 0
	done

	return 1
}

################################################################################
# List all available timezones
# Globals:
#     timezones
# Outputs:
#     "index": "timezone"
################################################################################
list_timezones() {
	for (( i = 0; i < ${#timezones[@]}; i++ )); do
		printf "%s: %s\n" "$i" "${timezones["$i"]}"
	done
}

################################################################################
# Check if timezone is valid
# Globals:
#     timezones
# Arguments:
#     string
# Returns:
#     0 if is a valid timezone, 1 if not
################################################################################
is_valid_timezone() {
	for timezone in "${timezones[@]}"; do
		[[ "$timezone" == "$1" ]] && return 0
	done

	return 1
}

################################################################################
# List all supported display drivers
# Globals:
#     drivers
# Outputs:
#     "index": "driver"
################################################################################
list_drivers() {
	for (( i = 0; i < ${#drivers[@]}; i++ )); do
		printf "%s: %s\n" "$i" "${drivers["$i"]}"
	done
}

################################################################################
# Check if display driver is supported
# Globals:
#     drivers
# Arguments:
#     string
# Returns:
#     0 if is a valid display driver, 1 if not
################################################################################
is_valid_driver() {
	for driver in "${drivers[@]}"; do
		[[ "$driver" == "$1" ]] && return 0
	done

	return 1
}

################################################################################
# Check if user name is valid
# Arguments:
#     string
# Returns:
#     0 if is a valid user name, 1 if not
################################################################################
is_valid_user() {
	echo "$1" | grep -q "^[a-z_][a-z0-9_-]*$"
}

################################################################################
# List all supported desktop environments
# Globals:
#     desktops
# Outputs:
#     "index": "desktop"
################################################################################
list_desktops() {
	for (( i = 0; i < ${#desktops[@]}; i++ )); do
		printf "%s: %s\n" "$i" "${desktops["$i"]}"
	done
}

################################################################################
# Check if desktop environment is supported
# Globals:
#     desktops
# Arguments:
#     string
# Returns:
#     0 if is a valid desktop environment, 1 if not
################################################################################
is_valid_desktop() {
	for desktop in "${desktops[@]}"; do
		[[ "$desktop" == "$1" ]] && return 0
	done

	return 1
}

################################################################################
# Prompt the user for a keymap
# Globals:
#     MSG_HELP_KEYMAP
#     MSG_CHOOSE_KEYMAP
#     MSG_SEARCH_KEYMAP
#     MSG_INVALID_KEYMAP
#     MSG_RETRY_KEYMAP
#     keymaps
################################################################################
prompt_keymap() {

	printf "%s\n%s" "$MSG_HELP_KEYMAP" "$MSG_CHOOSE_KEYMAP" && read -r keymap

	while ! (is_valid_keymap "$keymap"); do

		if is_help_string "$keymap"; then
			printf "%s" "$MSG_SEARCH_KEYMAP" && read -r search
			list_keymaps | grep -i "$search"
			printf "%s" "$MSG_CHOOSE_KEYMAP" && read -r keymap

			if is_number "$keymap"; then
				keymap=${keymaps["$keymap"]}
			fi

		else
			printf "${RED}%s${NC} %s" "$MSG_INVALID_KEYMAP" "$MSG_RETRY_KEYMAP" && read -r keymap

			if is_number "$keymap"; then
				keymap=${keymaps["$keymap"]}
			fi
		fi

	done

	export keymap && clear
}

################################################################################
# Prompt the user for a country
# Globals:
#     MSG_CHOOSE_COUNTRY
#     MSG_INVALID_COUNTRY
#     MSG_RETRY_COUNTRY
#     countries
################################################################################
prompt_country() {
	list_countries

	printf "%s" "$MSG_CHOOSE_COUNTRY" && read -r country

	while ! (is_valid_country "$country"); do
		if is_number "$country"; then
			country=${countries["$country"]}
		else
			printf "${RED}%s${NC} %s" "$MSG_INVALID_COUNTRY" "$MSG_RETRY_COUNTRY" && read -r country
		fi
	done

	export country && clear
}

################################################################################
# Prompt the user for a disk device to install the OS
# Globals:
#     MSG_CHOOSE_DISK
#     MSG_INVALID_DISK
#     MSG_RETRY_DISK
#     disks
################################################################################
prompt_disk() {
	list_disks

	printf "%s" "$MSG_CHOOSE_DISK" && read -r disk

	while ! (is_valid_disk "$disk"); do
		if is_number "$disk"; then
			disk=${disks["$disk"]}
		else
			printf "${RED}%s${NC} %s" "$MSG_INVALID_DISK" "$MSG_RETRY_DISK" && read -r disk
		fi
	done

	export disk && clear
}

################################################################################
# Prompt the user for a filesystem to format the disk with
# Globals:
#     MSG_CHOOSE_FS
#     MSG_INVALID_FS
#     MSG_RETRY_FS
#     filesystems
################################################################################
prompt_filesystem() {
	list_filesystems

	printf "%s" "$MSG_CHOOSE_FS" && read -r filesystem

	while ! (is_valid_filesystem "$filesystem"); do
		if is_number "$filesystem"; then
			filesystem=${filesystems["$fs"]}
		else
			printf "${RED}%s${NC} %s" "$MSG_INVALID_FS" "$MSG_RETRY_FS" && read -r filesystem
		fi
	done

	export filesystem && clear
}

################################################################################
# Prompt the user for a encryption password
# Globals:
#     MSG_ADD_CRYPT_PASSWD
#     MSG_CONFIRM_PASSWD
#     MSG_PASSWD_NO_MATCH
#     MSG_RETRY_PASSWD
################################################################################
prompt_crypt_passwd() {

	printf "%s" "$MSG_ADD_CRYPT_PASSWD" && read -r -s pass1 && printf "\n"
	printf "%s" "$MSG_CONFIRM_PASSWD" && read -r -s pass2

	while ! [ "$pass1" = "$pass2" ]; do
		printf "\n"
		printf "${RED}%s${NC} %s" "$MSG_PASSWD_NO_MATCH" "$MSG_RETRY_PASSWD" && read -r -s pass1 && printf "\n"
		printf "%s" "$MSG_CONFIRM_PASSWD" && read -r -s pass2
	done

	crypt_passwd="$pass1"
	export crypt_passwd && clear
}

################################################################################
# Prompt the user for a hostname
# Globals:
#     MSG_CHOOSE_HOSTNAME
################################################################################
prompt_hostname() {
	printf "%s" "$MSG_CHOOSE_HOSTNAME" && read -r hostname
	export hostname && clear
}

################################################################################
# Prompt the user for the root user password
# Globals:
#     MSG_ADD_PASSWD
#     MSG_CONFIRM_PASSWD
#     MSG_PASSWD_NO_MATCH
#     MSG_RETRY_PASSWD
################################################################################
prompt_passwd() {

	printf "%s" "$MSG_ADD_PASSWD" && read -r -s pass1 && printf "\n"
	printf "%s" "$MSG_CONFIRM_PASSWD" && read -r -s pass2

	while ! [ "$pass1" = "$pass2" ]; do
		printf "\n"
		printf "${RED}%s${NC} %s" "$MSG_PASSWD_NO_MATCH" "$MSG_RETRY_PASSWD" && read -r -s pass1 && printf "\n"
		printf "%s" "$MSG_CONFIRM_PASSWD" && read -r -s pass2
	done

	passwd="$pass1"
	export passwd && clear
}

################################################################################
# Prompt the user for a user name
# Globals:
#     MSG_ADD_USER
#     MSG_INVALID_USER
#     MSG_RETRY_USER
################################################################################
prompt_username() {

	printf "%s" "$MSG_ADD_USER" && read -r user

	while ! (is_valid_user "$user"); do
		printf "${RED}%s${NC} %s" "$MSG_INVALID_USER" "$MSG_RETRY_USER" && read -r user
	done

	export user && clear
}

################################################################################
# Prompt the user for a timezone
# Globals:
#     MSG_HELP_TIMEZONE
#     MSG_CHOOSE_TIMEZONE
#     MSG_SEARCH_TIMEZONE
#     MSG_INVALID_TIMEZONE
#     MSG_RETRY_TIMEZONE
#     timezones
################################################################################
prompt_timezone() {

	printf "%s\n%s" "$MSG_HELP_TIMEZONE" "$MSG_CHOOSE_TIMEZONE" && read -r timezone

	while ! (is_valid_timezone "$timezone"); do

		if is_help_string "$timezone"; then
			printf "%s" "$MSG_SEARCH_TIMEZONE" && read -r search
			list_timezones | grep -i "$search"
			printf "%s" "$MSG_CHOOSE_TIMEZONE" && read -r timezone

			if is_number "$timezone"; then
				timezone=${timezones["$timezone"]}
			fi

		else
			printf "${RED}%s${NC} %s" "$MSG_INVALID_TIMEZONE" "$MSG_RETRY_TIMEZONE" && read -r timezone

			if is_number "$timezone"; then
				timezone=${timezones["$timezone"]}
			fi
		fi

	done

	export timezone && clear
}

################################################################################
# Prompt the user for a display driver to install
# Globals:
#     MSG_CHOOSE_DRIVER
#     MSG_INVALID_DRIVER
#     MSG_RETRY_DRIVER
#     drivers
################################################################################
prompt_driver() {
	list_drivers

	printf "%s" "$MSG_CHOOSE_DRIVER" && read -r driver

	while ! (is_valid_driver "$driver"); do
		if is_number "$driver"; then
			driver=${drivers["$driver"]}
		else
			printf "${RED}%s${NC} %s" "$MSG_INVALID_DRIVER" "$MSG_RETRY_DRIVER" && read -r driver
		fi
	done

	export driver && clear
}

################################################################################
# Prompt the user for a desktop environment to install
# Globals:
#     MSG_CHOOSE_DESKTOP
#     MSG_INVALID_DESKTOP
#     MSG_RETRY_DESKTOP
#     desktops
################################################################################
prompt_desktop() {
	list_desktops

	printf "%s" "$MSG_CHOOSE_DESKTOP" && read -r desktop

	while ! (is_valid_desktop "$desktop"); do
		if is_number "$desktop"; then
			desktop=${desktops["$desktop"]}
		else
			printf "${RED}%s${NC} %s" "$MSG_INVALID_DESKTOP" "$MSG_RETRY_DESKTOP" && read -r desktop
		fi
	done

	export desktop && clear
}

################################################################################
# Display the configuration and prompt the user for install confirmation
# Globals:
#     MSG_REVIEW_CONFIGURATION
#     MSG_CONFIRMATION
#     MSG_START_INSTALL
#     MSG_COUNTDOWN_INSTALL
################################################################################
prompt_confirmation() {

	printf "%s\n\n" "$MSG_REVIEW_CONFIGURATION"
	print_configuration && printf "\n"

	printf "%s" "$MSG_CONFIRMATION" && read -r answer

	case "$answer" in
		"y"|"Y"|"") printf "\n${RED}%s${NC}\n\n%s" "$MSG_START_INSTALL" "$MSG_COUNTDOWN_INSTALL" ;;
		*) exit ;;
	esac

	clear
}

################################################################################
# Get all user input
################################################################################
get_user_input() {
	clear
	prompt_keymap
	prompt_country
	prompt_disk
	prompt_filesystem
	prompt_crypt_passwd
	prompt_hostname
	prompt_username
	prompt_passwd
	prompt_timezone
	prompt_driver
	prompt_desktop
	prompt_confirmation
}
