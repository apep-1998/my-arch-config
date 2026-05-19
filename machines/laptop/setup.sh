#!/bin/bash
# Laptop-specific post-install setup
USERNAME="$1"

# Enable TLP for battery management
systemctl enable tlp 2>/dev/null || true

# Add user to video group for backlight control
usermod -aG video "$USERNAME"
