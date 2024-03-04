#!/bin/bash

echo -ne "
------------------------------------------------------------------
 ░▒▓██████▓▒░ ░▒▓██████▓▒░░▒▓███████▓▒░░▒▓████████▓▒░▒▓███████▓▒░  
░▒▓█▓▒░░▒▓█▓▒░▒▓█▓▒░░▒▓█▓▒░▒▓█▓▒░░▒▓█▓▒░▒▓█▓▒░      ░▒▓█▓▒░░▒▓█▓▒░ 
░▒▓█▓▒░░▒▓█▓▒░▒▓█▓▒░      ░▒▓█▓▒░░▒▓█▓▒░▒▓█▓▒░      ░▒▓█▓▒░░▒▓█▓▒░ 
░▒▓█▓▒░░▒▓█▓▒░▒▓█▓▒▒▓███▓▒░▒▓█▓▒░░▒▓█▓▒░▒▓██████▓▒░ ░▒▓█▓▒░░▒▓█▓▒░ 
░▒▓█▓▒░░▒▓█▓▒░▒▓█▓▒░░▒▓█▓▒░▒▓█▓▒░░▒▓█▓▒░▒▓█▓▒░      ░▒▓█▓▒░░▒▓█▓▒░ 
░▒▓█▓▒░░▒▓█▓▒░▒▓█▓▒░░▒▓█▓▒░▒▓█▓▒░░▒▓█▓▒░▒▓█▓▒░      ░▒▓█▓▒░░▒▓█▓▒░ 
 ░▒▓██████▓▒░ ░▒▓██████▓▒░░▒▓█▓▒░░▒▓█▓▒░▒▓████████▓▒░▒▓█▓▒░░▒▓█▓▒░ 
------------------------------------------------------------------
Minimal Arch Installer
------------------------------------------------------------------
"               

pacman -Sy --needed --noconfirm archlinux-keyring

timedatectl set-ntp true

ZONE="/Europe/Skopje"

# ------------
# PARTITIONING
# ------------

# Define disk and partition sizes
BOOT_SIZE=300M   # Size for boot partition (e.g., 300MB)
SWAP_SIZE=2G     # Size for swap partition (e.g., 2GB)
ROOT_SIZE=       # Remaining space will be allocated to the root partition

# Disk to partition
DISK="/dev/sda"

# Unmount everything in /mnt if it's mounted
umount -A --recursive /mnt

# Disk preparation
echo "Preparing the disk..."
sgdisk -Z "${DISK}"           # Zap all on disk
sgdisk -a 2048 -o "${DISK}"   # New GPT disk with 2048 alignment

# Create partitions
echo "Creating partitions..."
sgdisk -n 1::+"$BOOT_SIZE" --typecode=1:ef00 --change-name=1:'EFIBOOT' "${DISK}"   # EFI Boot Partition
sgdisk -n 2::+"$SWAP_SIZE" --typecode=2:8200 --change-name=2:'SWAP' "${DISK}"      # Swap Partition
sgdisk -n 3::-0 --typecode=3:8300 --change-name=3:'ROOT' "${DISK}"                 # Root Partition

# Partprobe to reread partition table to ensure it is correct
echo "Rereading partition table..."
partprobe "${DISK}"

# Make filesystems
echo "Formatting partitions..."
mkfs.vfat "${DISK}1"    # Format EFI Boot Partition as FAT32
mkswap "${DISK}2"       # Format Swap Partition
mkfs.ext4 "${DISK}3"    # Format Root Partition as ext4

# Mount boot partition
echo "Mounting boot partition..."
mount "${DISK}1" /mnt/boot/efi

# Mount root partition
echo "Mounting root partition..."
mount "${DISK}3" /mnt

# Enable swap
echo "Enabling swap..."
swapon "${DISK}2"

# Output partition table
echo "Partition table:"
lsblk "${DISK}"


echo "Installing base system"

pacstrap -K /mnt base linux linux-firmware

echo "Generating fstab file"

genfstab -U /mnt >> /mnt/etc/fstab


arch-chroot /mnt <<EOF


echo "setting timezone"
ln -sf /usr/share/zoneinfo/$ZONE /etc/localtime

hwclock --systohc

echo "generating locale"
echo "en_US.UTF-8 UTF-8" > /etc/locale.gen
locale-gen

echo "setting LANG variable"
echo "LANG=en_US.UTF-8" > /etc/locale.conf

echo "setting console keyboard layout"
echo "KEYMAP=us" > /etc/vconsole.conf

echo "Set up your hostname"
echo "Enter your computer name: "
read hostname
echo $hostname > /etc/hostname
echo "Checking hostname (/etc/hostname)"
cat /etc/hostname


echo "setting up hosts file"
echo "127.0.0.1       localhost" >> /etc/hosts
echo "::1             localhost" >> /etc/hosts
echo "127.0.1.1       $hostname" >> /etc/hosts

echo "checking /etc/hosts file"
cat /etc/hosts

echo "Installing grub efibootmgr and networkmanager"

pacman -Sy --needed --noconfirm grub efibootmgr networkmanager

# Install GRUB
echo "Installing GRUB..."
grub-install --target=x86_64-efi --efi-directory=/mnt/boot/efi --bootloader-id=GRUB

# Generate GRUB Configuration
echo "Generating GRUB configuration..."
grub-mkconfig -o /mnt/boot/grub/grub.cfg

echo "Enabling NetworkManager"
systemctl enable NetworkManager


echo "Enter password for root user: "
passwd

echo "Adding regular user"
echo "Enter username to add a regular user: "
read username

useradd -m -g users -G wheel,audio,video -s /bin/bash $username
echo "Enter password for "$username": "
passwrd $username

echo "Giving sudo access to "$username"!"
echo "$username ALL=(ALL) ALL" >> /etc/sudoers.d/$username

EOF

umount -R /mnt
swapoff -a

echo "Arch Linux is installed, rebooting in 3 seconds"
sleep 3

reboot






                                                                   
