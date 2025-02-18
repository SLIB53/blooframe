# Blooframe

One of the most time-consuming, frustrating, and sometimes discouraging parts of experimenting with software is having to set up an environment before even beginning to explore. As you probably know, these environments can quickly break and need to be rebuilt, especially when working with bleeding edge packages that might corrupt the system. For that reason, I've taken care to document the creation of a home lab environment. While I've used virtual machines and containers in the past, this time the aim is to deploy an independent stack on bare metal.

Since I have faith in public knowledge, this public repository contains knowledge of a home lab setup, however the contents of this repository are mainly for my personal use. If you are a lifelong student of this sort of thing, or maybe you're just curious, feel free to browse the repo and leave any questions, comments, tips, or concerns in the issues.

## Install Guide

To fully install to a _target_ computer, a Linux live installation media is used to serve an _administrator_ computer on the same network that will preload, load and bootstrap the target through SSH.

### Preload

To begin this process, a live installation media will need to be made. Blooframe uses Arch Linux, so you will need to download and create a live media from [archlinux.org](https://archlinux.org). There are several ways to do this, but regardless of how you do this, it is a good idea to **store an Arch Linux ISO in the "Frame System Partition" overlay at `overlays/frame-system-partition/frame/lavian/os`**. The `overlays` directory contains directory trees that will be copied onto the target.

> **Tip:** Use `dd` to create a live USB from macOS. First, attach and discover the disk's device name, and then format it with the Arch Linux image.

``` zsh
diskutil list | tee /tmp/diskutil-list-before.out

# INTERVENTION: Insert USB drive.

diff /tmp/diskutil-list-before.out <(diskutil list) # INTERVENTION: Take note of the device path (ex '/dev/disk6'). For this tip, store the correct path in the USB_DISK_PATH variable.
```

```sh
sudo umount /dev/$USB_DISK_PATH
sudo dd if=./overlays/frame-system-partition-overlay/lavian/os/archlinux-2025.02.01-x86_64.iso of=$USB_DISK_PATH bs=1M status=progress oflag=direct # CAUTION: This will erase existing data on the device.
```

Once the media is ready, the target can be set up to handle SSH connections. On the **target**, boot from the installation media, set up OpenSSH, then connect to the same network as the administrator.

```sh
passwd root # follow prompt

echo 'PermitRootLogin yes' >> /etc/ssh/sshd_config
```

```sh
iwctl # only for wifi, follow prompt
```

```sh
ip address show # INTERVENTION: Take note of the IP address. For this guide, store the correct address in the BLOOFRAME_INSTALL_TARGET_IP variable.
```


### Load

All the installation resources can now be loaded onto the target. Simply upload resources to the target by running `rsync` on the **administrator**.

```sh
rsync --recursive ./overlays root@$BLOOFRAME_INSTALL_TARGET_IP:/tmp/blooframe
```

> **Tip:** Pass the `--human-readable` and `--progress` flags to watch the transfer. Additionally, on macOS, you may have `.DS_Store` files that would be irrelevant to upload. You can exclude them with the `--exclude` flag. (ex. `rsync --recursive --exclude .DS_Store --human-readable --progress ./overlays root@$BLOOFRAME_INSTALL_TARGET_IP:/tmp/blooframe`)


### Bootstrap

Finally, finish this process by bootstrapping the machine. To bootstrap, you will need to format the disk, set up the "EFI System Partition", set up the "Frame System Partition", and set up the hosts (currently just "lavian").

Thanks to the efforts made in prior phases, the entirety of this phase can be executed on the **target**.

> **Tip:** since an SSH connection is already established, it's probably most convenient to continue executing remotely from the administrator. (ex. `ssh root@$BLOOFRAME_INSTALL_TARGET_IP`)

To format the disk, first discover it with `lsblk`, and then pass the disk device name to the `partition.sh` script.

```sh
lsblk # INTERVENTION: Take note of the device name. In this example, store the name (ex. 'nvme0n1') in the BLOOFRAME_INSTALL_TARGET_DISK variable.
```

```sh
FRAME_NVME_DISK=$BLOOFRAME_INSTALL_TARGET_DISK sh /tmp/blooframe/overlays/efi-system-partition-overlay/EFI/SLIB53/Blooframe/partition.sh
```

> **Tip:** Since the drive has been recently reformatted, now is a good time to clear out old EFI entries using `efibootmgr`.

Having formatted and partitioned the disk, sync the overlays to their appropriate partitions.

```sh
mount --mkdir /dev/$BLOOFRAME_INSTALL_TARGET_DISK'p1' /mnt/esp \
    && rsync --recursive /tmp/blooframe/overlays/efi-system-partition-overlay/ /mnt/esp/
```

```sh
mount --mkdir /dev/$BLOOFRAME_INSTALL_TARGET_DISK'p2' /mnt/fsp \
    && rsync --recursive /tmp/blooframe/overlays/frame-system-partition-overlay/ /mnt/fsp/
```

Finally, set up the first host, lavian.

```sh
FRAME_NVME_DISK=$BLOOFRAME_INSTALL_TARGET_DISK NON_ROOT_USER=bloo sh /mnt/fsp/lavian/setup.sh # follow post-installation advice
```

Hopefully, this guide has demonstrated an easy way to get a useful home lab environment. If you've followed this guide successfully, you should now have a lab ready to go!

In the course of experimentation, things might break and crash, but the ability to rebuild the environment is documented on the overlaid partitions.


----

## License

This software is licensed under the [MIT No Attribution License](https://opensource.org/license/mit-0).
