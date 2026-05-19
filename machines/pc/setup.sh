#!/bin/bash
# PC-specific post-install setup
USERNAME="$1"

# Set up ROCm environment for the user
ROCm_ENV="$HOME_DIR/.config/zsh_local"
cat > "/home/$USERNAME/.config/zsh_local" <<'EOF'
# ROCm (AMD GPU compute)
if [ -d /opt/rocm/bin ]; then
    export PATH="/opt/rocm/bin:$PATH"
    export LD_LIBRARY_PATH="/opt/rocm/lib:${LD_LIBRARY_PATH:-}"
fi
EOF
chown "$USERNAME:users" "/home/$USERNAME/.config/zsh_local"

# Add user to video group for ROCm access
usermod -aG video "$USERNAME"
