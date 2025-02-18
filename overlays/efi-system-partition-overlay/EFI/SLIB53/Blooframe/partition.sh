#! /bin/sh

# CAUTION: Running this script will forfeit all data on the device.

# How to use:
#
#   Variables:
#       FRAME_NVME_DISK    Linux device name of the NVMe disk that will be formatted (ex. nvme0n1)
#
#   Example:
#       FRAME_NVME_DISK=nvme0n1 ./partition.sh # CAUTION: This will forfeit all data on the device.

# Further considerations:
#   - Support devices enumerated as sdX

blkdiscard --force /dev/$FRAME_NVME_DISK

parted /dev/$FRAME_NVME_DISK --script 'mklabel gpt'

# NOTE: While I still pass the optimal alignment flag, the sectors have already been aligned by hand. (512 B per sector, 1 MiB alignment)

parted /dev/$FRAME_NVME_DISK --script -a optimal 'mkpart "EFI system partion"        2048s       409599s'     # (    407,552 sectors /     208,666,624 B /     200 MiB) total size
parted /dev/$FRAME_NVME_DISK --script -a optimal 'mkpart "Frame system partion"      409600s     157208575s'  # (156,798,976 sectors /  80,281,075,712 B /  76,562 MiB) total size
parted /dev/$FRAME_NVME_DISK --script -a optimal 'mkpart "Root partition"            157208576s  1078808575s' # (921,600,000 sectors / 471,859,200,000 B / 450,000 MiB) total size

# Remaining free space, NVMe CA6-8D1024 (2,000,409,264 sectors)                                                 (921,600,655 sectors / 471,859,535,360 B / 450,000 MiB) total size

parted /dev/$FRAME_NVME_DISK --script 'set 1 esp on'

mkfs.fat -F 32  /dev/$FRAME_NVME_DISK'p1'
mkfs.ext4       /dev/$FRAME_NVME_DISK'p2'
