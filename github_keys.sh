#!/bin/bash

sudo apt-get install gh -y
# Generate SSH key if it doesn't exist
if [ ! -f ~/.ssh/id_rsa ]; then
    ssh-keygen -t rsa -b 4096 -C "31909722+eduuh@users.noreply.github.com" -N "" -f ~/.ssh/id_rsa
fi

# Start the SSH agent and add the key
eval "$(ssh-agent -s)"
ssh-add ~/.ssh/id_rsa

gh auth refresh -h github.com -s admin:public_key

# Add SSH key to GitHub using gh CLI
gh ssh-key add ~/.ssh/id_rsa.pub --title "Automated Key $(date +%Y-%m-%d)"

echo "SSH key added to GitHub successfully."
