#!/bin/bash

# Specify the SD card device manually here

echo "Make sure to check the name of the SD card using lsblk and change it in the script."

SD_CARD="/dev/sdb1"  # Change this to /dev/sdb1 if needed on another machine

# Variables
MAPPED_NAME="sdcard"               # Name to map the encrypted device in /dev/mapper
MOUNT_POINT="/mnt/sdcard"          # Mount point
USER_NAME="$USER"                  # Automatically gets the current user

# Function to mount the SD card
mount_sdcard() {
    echo "Unlocking and mounting the SD card..."

    # Unlock the encrypted SD card
    sudo cryptsetup luksOpen "$SD_CARD" "$MAPPED_NAME"
    if [ $? -ne 0 ]; then
        echo "Failed to unlock the SD card."
        exit 1
    fi

    # Create mount point if it doesn't exist
    if [ ! -d "$MOUNT_POINT" ]; then
        sudo mkdir -p "$MOUNT_POINT"
    fi

    # Mount the unlocked SD card
    sudo mount /dev/mapper/"$MAPPED_NAME" "$MOUNT_POINT"
    if [ $? -eq 0 ]; then
        echo "SD card successfully mounted at $MOUNT_POINT"

        # Change ownership to the current user
        sudo chown -R "$USER_NAME":"$USER_NAME" "$MOUNT_POINT"
        echo "Mount point ownership changed to user: $USER_NAME"
    else
        echo "Failed to mount the SD card."
        sudo cryptsetup luksClose "$MAPPED_NAME"
        exit 1
    fi
}

# Function to unmount the SD card
unmount_sdcard() {
    echo "Unmounting the SD card..."

    # Unmount the SD card
    sudo umount "$MOUNT_POINT"
    if [ $? -eq 0 ]; then
        echo "SD card unmounted."
    else
        echo "Failed to unmount the SD card."
        exit 1
    fi

    # Close the LUKS device
    sudo cryptsetup luksClose "$MAPPED_NAME"
    if [ $? -eq 0 ]; then
        echo "SD card locked and closed."
    else
        echo "Failed to close the LUKS device."
        exit 1
    fi
}

# Main script logic
echo "Would you like to (m)ount or (u)mount the SD card?"
read -r action

if [[ "$action" == "m" ]]; then
    mount_sdcard
elif [[ "$action" == "u" ]]; then
    unmount_sdcard
else
    echo "Invalid option. Use 'm' to mount or 'u' to unmount."
    exit 1
fi
