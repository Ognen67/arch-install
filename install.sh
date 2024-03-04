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

lsblk

echo "Enter the drive you'd like to install arch linux on. ("/dev/sda", "/dev/nvme0n1" or something else)"
read drive

lsblk
echo "Choose which disk utility tool you'd like to use to partition your drive"
echo "1. fdisk"
echo "2. cfdisk"
echo "3. gdisk"
echo "4. parted"
read partitionutility

case "$partitionutility" in 
    1 | fdisk | Fdisk | FDISK) 
    partitionutility="fdisk"
    ;;
    2 | cfdisk | Cfdisk | CFDISK) 
    partitionutility="cfdisk"
    ;;
    3 | gdisk | Gdisk | GDISK) 
    partitionutility="cfdisk"
    ;;
    4 | parted | Parted | PARTED) 
    partitionutility="parted"
    ;;
    *)
    echo "Unknown or unsupported disk partitioning utility! Default is cfdisk"
    partitionutility="cfdisk"
    ;;
esac

echo ""$partitionutility" is the selected disk utility "

clear

echo "Getting ready for creating partitions!"
echo "root and boot partitions are mandatory."
echo "home and swap partitions are optional but recommended!"
echo "Also, you can create a separate partition for timeshift backup (optional)!"
echo "Getting ready in 9 seconds"

"$partitionutility" "$drive"

clear

lsblk

echo "choose your linux file system type for formatting drives"

echo "choose your linux file system type for formatting drives"
echo " 1. ext4"
echo " 2. xfs"
echo " 3. btrfs"
echo " 4. f2fs"
echo " Boot partition will be formatted in fat32 file system type."
read filesystemtype

case "$filesystemtype" in
    1 | ext4 | Ext4 | EXT4)
    filesystemtype="ext4"
    ;;
    2 | xfs | Xfs | XFS)
    filesystemtype="xfs"
    ;;
    3 | btrfs | Btrfs | BTRFS)
    filesystemtype="btrfs"
    ;;
    4 | f2fs | F2fs | F2FS)
    filesystemtype="f2fs"
    ;;
    *)
    echo "Unknown or unsupported Filesystem. Default = ext4."
    filesystemtype="ext4"
    ;;
esac

echo ""$filesystemtype" is the selected file system type."

clear

echo "Getting ready for formatting drives."

lsblk

echo "Enter the root partition (ex: /dev/sda1): "
read rootpartition

mkfs."$filesystemtype" "$rootpartition"
mount "$rootpatition" /mnt

clear
lsblk

read -p "Did you also create separate home partition [y/n]: " answerhome
case "$answerhome" in
    y | Y | yes | Yes | YES)
    echo "Enter home partition (ex: /dev/sda2): "
    read homepartition
    mkfs."$filesystemtype" "$homepartition"
    mkdir /mnt/home
    mount "$homepartition" /mnt/home
    ;;
    *)
    echo "Skipping home partition!"
    ;;
esac
clear
lsblk
read -p "Do you want to create a swap partition? [y/n]: " answeswap
case "$answerswap" in
    y | Y | yes | Yes | YES)
    echo "Enter swap partition (ex: /dev/sda3): "
    read swappartition
    mkswap "$swappartition"
    swapon "$swappartition"
    ;;
    *)
    echo "Skipping swap partition"
    ;;
esac

clear lsblk

read -p "Enter the boot partition drive (ex. /dev/sda4): " answefi
mkfs.fat -F 32 "$answerfi"
clear
lsblk

clear
clear

echo "Installing base system"

pacstrap -K /mnt base linux linux-firmware

clear
echo "Generating fstab file"

genfstab -U /mnt >> /mnt/etc/fstab

clear

arch-chroot /mnt
clear

echo "setting timezone"
ln -sf /usr/share/zoneinfo/Europe/Skopje /etc/localtime

hwclock --systohc

echo "generating locale"
echo "en_US.UTF-8 UTF-8" > /etc/locale.gen
locale-gen


clear

echo "setting LANG variable"
echo "LANG=en_US.UTF-8" > /etc/locale.conf

clear

echo "setting console keyboard layout"
echo "KEYMAP=us" > /etc/vconsole.conf

clear

echo "Set up your hostname!"
echo "Enter your computer name: "
read hostname
echo $hostname > /etc/hostname
echo "Checking hostname (/etc/hostname)"
cat /etc/hostname

clear

echo "setting up hosts file"
echo "127.0.0.1       localhost" >> /etc/hosts
echo "::1             localhost" >> /etc/hosts
echo "127.0.1.1       $hostname" >> /etc/hosts
clear

echo "checking /etc/hosts file"
cat /etc/hosts

clear

echo "Installing grub efibootmgr and networkmanager"

pacman -Sy --needed --noconfirm grub efibootmgr networkmanager
clear

lsblk
echo "Enter the boot partition to install bootloader. (ex: /dev/sda4): "
read efipartition
efidirectory="/boot/efi/"

if [ ! -d "$efidirectory" ]; then
    mkdir -p efidirectory
fi

mount "$efipartition" "$efidirectory"
clear
lsblk

echo "Installing grub bootloader in /boot/efi partition"
grub-install --target=x86_64-efi --efi-directory=/boot/efi --boatloader-id=GRUB --removable
grub-mkconfig -o /boot/grub/grub.cfg

clear

echo "Enabling NetworkManager"
systemctl enable NetworkManager

clear

echo "Enter password for root user: "
passwd
clear

echo "Adding regular user"
echo "Enter username to add a regular user: "
read username

useradd -m -g users -G wheel,audio,video -s /bin/bash $username
echo "Enter password for "$username": "
passwrd $username
clear

echo "Giving sudo access to "$username"!"
echo "$username ALL=(ALL) ALL" >> /etc/sudoers.d/$username
cler

exit
reboot






                                                                   
