#!/bin/bash

# 1. Define your menu items: ["Display Name"]="Command"
declare -A MENU
MENU=(
    ["🔒 Lock"]="bash $HOME/.config/i3/scripts/lock.sh"
    ["🚪 Logout"]="i3-msg exit"
    ["🔌 System Reboot"]="reboot"
    ["⚡ Shutdown"]="shutdown now"
)

# 2. Extract the keys (the display names) to show in Rofi
# We use printf to join them with newlines
LIST=$(printf "%s\n" "${!MENU[@]}" | sort)

# 3. Show the menu and capture the selection
# -dmenu: list mode | -i: case-insensitive | -p: prompt text
CHOICE=$(echo -e "$LIST" | rofi -dmenu -i -p "Execute:")

# 4. Run the command associated with the choice
if [[ -n "$CHOICE" ]]; then
    # Use eval to handle complex commands with arguments/quotes
    eval "${MENU[$CHOICE]}"
else
    echo "No selection made. Exiting."
fi
