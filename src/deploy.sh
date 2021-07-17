#!/bin/bash
# Script to deploy the installer

# Repository link and files
REPO_LINK="https://raw.githubusercontent.com/pedroclobo/arch/main/src/"
files=("install.sh" "library.sh" "stdin.sh")

# Dependency packages
pacman -Syy wget --noconfirm >/dev/null 2>&1

# Download the files and make them executable
for file in "${files[@]}"
do
	wget -q "${REPO_LINK}""$file"
	chmod +x "$file"
done

# Start the installer
bash install.sh
