#!/bin/bash

MOUNT_DIR="gnu-linux-img"

# Find the loop device associated with the mount directory
LOOP_DEV=$(mount | grep "$MOUNT_DIR" | awk '{print $1}')

# Unmount the directory if mounted
if mountpoint -q "$MOUNT_DIR"; then
    sudo umount "$MOUNT_DIR"
    echo "Unmounted $MOUNT_DIR"
else
    echo "$MOUNT_DIR is not mounted"
fi

# Remove the loop device
if [ -n "$LOOP_DEV" ]; then
    sudo losetup -d "$LOOP_DEV"
    echo "Loop device $LOOP_DEV removed"
else
    echo "No loop device found"
fi

# Remove the mount directory
if [ -d "$MOUNT_DIR" ]; then
    rmdir "$MOUNT_DIR"
    echo "Removed directory $MOUNT_DIR"
fi
