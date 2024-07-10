#!/bin/bash

# Display a message with sudo
sudo echo "Hello.."

# Function to add linuxvnc startup command to .profile for a specific TTY
# Usage: add_linuxvnc_to_profile TTY_NUMBER LINUXVNC_COMMAND
add_linuxvnc_to_profile() {
    local tty_number=$1
    local linuxvnc_command=$2
    
    # Get the current user
    current_user=$(whoami)
    
    # Check if .profile exists, create it if it doesn't
    if [ ! -f /home/$current_user/.profile ]; then
      echo ".profile not found. Creating .profile for user $current_user."
      echo "# .profile" > /home/$current_user/.profile
      echo "# This file is executed by the command interpreter for login shells." >> /home/$current_user/.profile
      echo "" >> /home/$current_user/.profile
    fi
    
    # Append linuxvnc command to .profile if not already added
    if ! grep -q "linuxvnc $tty_number" /home/$current_user/.profile; then
      echo "# Start linuxvnc on TTY$tty_number" >> /home/$current_user/.profile
      echo "if [ \"\$TTY\" = \"/dev/tty$tty_number\" ]; then" >> /home/$current_user/.profile
      echo "    $linuxvnc_command &" >> /home/$current_user/.profile
      echo "fi" >> /home/$current_user/.profile
      echo "Added linuxvnc startup command for TTY$tty_number to .profile."
    else
      echo "linuxvnc command for TTY$tty_number already present in .profile."
    fi
}

# Show the OS version and ask for confirmation
os_description=$(lsb_release -d | awk -F'\t' '{print $2}')
echo "You are running $os_description."

read -p "Are you sure you want to run this script? (y/n) " choice

if [[ "$choice" != "y" && "$choice" != "Y" ]]; then
  echo "Script execution canceled."
  exit 1
fi

# Get the current user
current_user=$(whoami)

# Backup the current sudoers file (assuming sudo access)
sudo cp /etc/sudoers /etc/sudoers.bak

# Add the user to the sudoers file with no password requirement (assuming sudo access)
echo "$current_user ALL=(ALL) NOPASSWD:ALL" | sudo tee /etc/sudoers.d/$current_user

# Verify the sudoers file syntax (assuming sudo access)
sudo visudo -cf /etc/sudoers.d/$current_user

if [[ $? -eq 0 ]]; then
  echo "Successfully updated sudoers file for user $current_user."
else
  echo "Failed to update sudoers file. Restoring from backup."
  sudo mv /etc/sudoers.bak /etc/sudoers
  exit 1
fi

# Create and enable additional TTYs with autologin (assuming sudo access)
for i in {2..12}; do
  sudo cp /lib/systemd/system/getty@.service /etc/systemd/system/getty@tty$i.service
  sudo sed -i "s/ExecStart=-\/sbin\/agetty -o '-p -- \\u' --noclear %I $TERM/ExecStart=-\/sbin\/agetty --autologin $current_user --noclear %I $TERM/" /etc/systemd/system/getty@tty$i.service
  sudo systemctl enable getty@tty$i.service
  sudo systemctl start getty@tty$i.service
done

# Set TTY2 as the default visible TTY on boot (assuming sudo access)
sudo cp /etc/default/grub /etc/default/grub.bak
sudo sed -i 's/GRUB_CMDLINE_LINUX=""/GRUB_CMDLINE_LINUX="vt.default_utf8=1"/' /etc/default/grub
sudo update-grub

echo "chvt 2" | sudo tee /etc/init.d/switch-to-tty2
sudo chmod +x /etc/init.d/switch-to-tty2
sudo update-rc.d switch-to-tty2 defaults

# Add linuxvnc startup command to .profile for TTY3
add_linuxvnc_to_profile 3 "linuxvnc 3 -rfbport 5903"

# Add linuxvnc startup command to .profile for TTY7
add_linuxvnc_to_profile 7 "linuxvnc 1 -rfbport 5901"

# Add linuxvnc startup command to .profile for TTY8
add_linuxvnc_to_profile 8 "linuxvnc 2 -rfbport 5902"

# Add linuxvnc startup command to .profile for TTY9
add_linuxvnc_to_profile 9 "linuxvnc 3 -rfbport 5903"

# Add linuxvnc startup command to .profile for TTY10
add_linuxvnc_to_profile 10 "linuxvnc 4 -rfbport 5904"

# Add linuxvnc startup command to .profile for TTY11
add_linuxvnc_to_profile 11 "linuxvnc 5 -rfbport 5905"

# Add linuxvnc startup command to .profile for TTY12
add_linuxvnc_to_profile 12 "linuxvnc 6 -rfbport 5906"

echo "Successfully configured auto-login for $current_user on TTYs 2-12, set TTY2 as the default on boot, and added linuxvnc startup commands to .profile for TTY3, TTY7, TTY8, TTY9, TTY10, TTY11, and TTY12."
