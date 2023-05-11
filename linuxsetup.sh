#!/bin/bash

# Check if an argument was provided
if [ $# -eq 0 ]; then
  echo "Error: No argument provided."
  exit 1
fi

# Store the argument in a variable
action=$1
folder_path=""

# Perform an action based on the argument
if [ $action == "update" ]; then
  echo "Updating Local..."
  # Set the path to the folder
  folder_path="~/.config/nvim"

elif [ $action == "new" ]; then
  echo "Copying new files..."
  # Set the path to the folder
  folder_path="./AppData/Local/nvim"
else
  echo "Error: Unknown argument. Either copy or update"
  echo "Example:"
  echo "linuxsetup update"
  exit 1
fi


# Check if the folder exists
if [ -d "$folder_path" ]; then
  # If the folder exists, delete it
  rm -rf "$folder_path"
fi

# Create the folder

if [ $action == "update" ]; then
   cp -r ./AppData/Local/nvim ~/.config
elif [ $action == "new" ]; then
   cp -r ~/.config/nvim ./AppData/Local/
fi

echo "Done: :)"

