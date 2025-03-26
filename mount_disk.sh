#!/bin/bash

IMG_FILE="gnu-linux.img"
MOUNT_DIR="gnu-linux-img"

# Create mount directory if it does not exist
if [ ! -d "$MOUNT_DIR" ]; then
    mkdir "$MOUNT_DIR"
fi

# Set up loop device
LOOP_DEV=$(sudo losetup --find -P --show "$IMG_FILE")

# Mount the image
sudo mount "$LOOP_DEV""p1" "$MOUNT_DIR"

echo "Image mounted at $MOUNT_DIR using loop device $LOOP_DEV"

