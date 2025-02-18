#! /bin/sh

# How to use:
#   Before running this script from an Arch Linux live media, set up partitions and connect to the internet.
#   The EFI system partition is expected to be the first partition.
#
#   Variables:
#       FRAME_NVME_DISK     Linux device name of the NVMe disk containing the blooframe installation. (ex. nvme0n1)
#       NON_ROOT_USER       Name of the first non-root user (ex. lavian)
#
#   Example:
#       FRAME_NVME_DISK=nvme0n1 NON_ROOT_USER=bloo ./lavian.sh

# Further considerations:
#   - create a root btrfs snapshot
#   - Support ostree

EFI_SYSTEM_PARTITION=$FRAME_NVME_DISK'p1'
LAVIAN_ROOT_PARTITION=$FRAME_NVME_DISK'p3'

mkfs.btrfs --force --label lavian-root-fs /dev/$LAVIAN_ROOT_PARTITION

mount --mkdir /dev/$EFI_SYSTEM_PARTITION /mnt/$EFI_SYSTEM_PARTITION
mount --mkdir /dev/$LAVIAN_ROOT_PARTITION /mnt/$LAVIAN_ROOT_PARTITION

mkdir -p /mnt/$EFI_SYSTEM_PARTITION/lavian && mount --bind --mkdir /mnt/$EFI_SYSTEM_PARTITION/lavian /mnt/$LAVIAN_ROOT_PARTITION/boot

pacstrap -K /mnt/$LAVIAN_ROOT_PARTITION base linux linux-firmware

efibootmgr --create --disk /dev/$FRAME_NVME_DISK --label "Lavian" --loader "\\lavian\\vmlinuz-linux" --unicode initrd="\\lavian\\initramfs-linux.img root=/dev/$LAVIAN_ROOT_PARTITION rw quiet"

arch-chroot /mnt/$LAVIAN_ROOT_PARTITION bash << ARCH_CHROOT_EOF

# Hostname

echo 'lavian' > /etc/hostname


# Users

echo "root" | passwd --stdin root

useradd --create-home --user-group $NON_ROOT_USER
echo "$NON_ROOT_USER" | passwd --stdin $NON_ROOT_USER


# Always on

cat << EOF >> /etc/systemd/logind.conf
HandleLidSwitch=ignore
HandleLidSwitchExternalPower=ignore
HandleLidSwitchDocked=ignore
EOF


# TODO: NVIDIA Drivers


# Wireless Networking

pacman -S --noconfirm iwd

systemctl enable systemd-networkd.service

systemctl enable systemd-resolved.service

mkdir /etc/iwd
cat << EOF > /etc/iwd/main.conf
[General]
EnableNetworkConfiguration=true

[Network]
NameResolvingService=systemd
EOF
systemctl enable iwd.service


# OpenSSH

pacman -S --noconfirm openssh

systemctl enable sshd.service


# Podman

pacman -S --noconfirm podman


# Fish

pacman -S --noconfirm fish

chsh --shell /usr/bin/fish root
chsh --shell /usr/bin/fish $NON_ROOT_USER

ARCH_CHROOT_EOF


# Post-Installation

cat << EOF
Remaining tasks:
    - Check the boot loader options with 'efibootmgr'.

    - Change the default root password. (default is 'root')
    - Change the default non-root user password. (default is '$NON_ROOT_USER')

    - Optionally, review other configurations. (e.g. time, locale, /etc/systemd/logind.conf, etc.)
EOF
