#!/bin/bash

# This script will replace the default colemak layout
# Using a hard link to link to the right config file

KEYBOARD=/usr/share/X11/xkb/symbols/Keyboard.bak

if [ -f "$KEYBOARD" ]; then
   echo "removed old backup keyboard $KEYBOARD"
   sudo rm -rf $KEYBOARD
 fi

echo "Creating a new backup file"
sudo mv  /usr/share/X11/xkb/symbols/us $KEYBOARD

if [ -f "$KEYBOARD" ]; then
   echo "Removing existing hard link"
fi

echo "Creating a new hard Link"
sudo ln ./Systems/Linux/us /usr/share/X11/xkb/symbols/us
