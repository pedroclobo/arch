#!/bin/bash
# Script to deploy the installer

# Dependency files
INSTALL="https://raw.githubusercontent.com/pedroclobo/arch/main/src/install.sh"
LIBRARY="https://raw.githubusercontent.com/pedroclobo/arch/main/src/library.sh"
STDIN="https://raw.githubusercontent.com/pedroclobo/arch/main/src/stdin.sh"

# Download the files
wget "$INSTALL"
wget "$LIBRARY"
wget "$STDIN"

# Make the files executable
chmod +x install.sh library.sh stdin.sh

# Start the installer
bash install.sh
