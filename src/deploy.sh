#!/bin/bash
# Script to deploy the installer

# Install dependencies
pacman -Syy wget --noconfirm >/dev/null 2>&1

# Download the files and make them executable
file_deps=("https://raw.githubusercontent.com/pedroclobo/arch/main/src/install.sh" \
           "https://raw.githubusercontent.com/pedroclobo/arch/main/src/lib/disk.sh" \
           "https://raw.githubusercontent.com/pedroclobo/arch/main/src/lib/package.sh" \
           "https://raw.githubusercontent.com/pedroclobo/arch/main/src/lib/stdin.sh" \
		   "https://raw.githubusercontent.com/pedroclobo/arch/main/src/lib/system.sh")

for file in "${file_deps[@]}"; do
	wget -q "$file"
	chmod +x "${file##*/}"
done

# Start the installer
bash install.sh
