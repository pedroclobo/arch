#!/bin/bash
# Script to deploy the installer

# Repository link and files
MAIN_REPO_LINK="https://raw.githubusercontent.com/pedroclobo/arch/main/src/"
main_files=("install.sh")

LIB_REPO_LINK="https://raw.githubusercontent.com/pedroclobo/arch/main/src/lib/"
lib_files=("disk.sh" "package.sh" "stdin.sh" "system.sh")


# Dependency packages
pacman -Syy wget --noconfirm >/dev/null 2>&1

# Download the files and make them executable
for file in "${main_files[@]}"
do
	wget -q "${MAIN_REPO_LINK}""$file"
	chmod +x "$file"
done

for file in "${lib_files[@]}"
do
	wget -q "${LIB_REPO_LINK}""$file"
	chmod +x "$file"
done

# Start the installer
bash install.sh
