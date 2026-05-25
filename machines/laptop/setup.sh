#!/bin/bash
# Laptop-specific post-install setup
USERNAME="$1"

# Enable TLP for battery management
systemctl enable tlp 2>/dev/null || true

# Add user to video group for backlight control
usermod -aG video "$USERNAME"

# Fingerprint auth: enable pam_fprintd.so at the top of the system-auth stack.
# Marked "sufficient" so a successful swipe short-circuits the rest (no
# password prompt); a failed swipe falls through to pam_unix.so as normal.
# system-auth cascades to sudo, i3lock, sddm, and tty login, so this single
# edit covers every place that asks for the user password.
PAM_FILE=/etc/pam.d/system-auth
if [ -f "$PAM_FILE" ] && ! grep -q 'pam_fprintd.so' "$PAM_FILE"; then
    awk '
      !done && /^auth[[:space:]]/ {
        print "auth       sufficient                  pam_fprintd.so"
        done = 1
      }
      { print }
    ' "$PAM_FILE" > "$PAM_FILE.new" && mv "$PAM_FILE.new" "$PAM_FILE"
    echo "[OK] inserted pam_fprintd.so into $PAM_FILE"
fi
