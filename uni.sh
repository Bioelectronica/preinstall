#!/bin/sh
#------------------------------------------------------------- partition and format
T="/dev/mmcblk0"
P="p"
A=$T"$P"1	# boot
B=$T"$P"2	# swap
C=$T"$P"3	# home
D=$T"$P"4	# root
X="/sys/class/dmi/id/product_uuid"
parted -s $T mklabel gpt 
parted -s $T mkpart primary fat32 1MiB 261MiB
parted -s $T set 1 esp on
parted -s $T mkpart primary linux-swap 261MiB 8000MiB
parted -s $T mkpart non-fs 8000MiB 32000MiB
parted -s $T mkpart primary ext4 32000MiB 100%
partprobe $T
sleep 0.1
mkfs.fat -F32 $A		# boot
sleep 0.1			# boot
mkswap $B			# swap
sleep 0.1			# swap
cryptsetup luksFormat $C	# home
cryptsetup luksAddKey $C $X	# home
cryptsetup luksOpen $C gtr	# home
mkfs.ext4 /dev/mapper/gtr	# home
sleep 0.1			# home
mkfs.ext4 $D			# root
sleep 0.1			# root
#------------------------------------------------------------- mounts and make chroot
cp /root/arch_install_scripts/mirrorlist /etc/pacman.d/
pacman -Sy
mount $D /mnt			# mount root
mkdir /mnt/boot			# mount boot
mount $A /mnt/boot		# mount boot
mkdir /mnt/home			# mount home
mount /dev/mapper/gtr /mnt/home	# mount home
pacstrap /mnt base base-devel linux linux-firmware intel-ucode linux-headers efibootmgr networkmanager openssh \
nano mc vi vim man-db man-pages git sudo reflector usbutils htop nload ncdu iotop dosfstools parted \
nmap wget xorg-server xorg-xinit xterm openbox ttf-dejavu ttf-liberation tint2 network-manager-applet \
tigervnc pyxdg bluez-utils blueman
# reflector includes python
genfstab -U /mnt >> /mnt/etc/fstab
cp /etc/pacman.d/mirrorlist /mnt/etc/pacman.d/
echo "gtr $C $X luks" >> /mnt/etc/crypttab
chmod 400 /mnt/etc/crypttab
# echo "/dev/mapper/gtr /home/saveguest/git-repos ext4 rw,sync,nofail 0 0" >> /mnt/etc/fstab
#------------------------------------------------------------- boot configuration
arch-chroot /mnt bootctl --path=/boot install 
cat - > /mnt/boot/loader/loader.conf << EOF
default arch
EOF
cat - > /mnt/boot/loader/entries/arch.conf << EOF
title Bioelectronica
linux /vmlinuz-linux
initrd /intel-ucode.img
initrd /initramfs-linux.img
options root=$D rw
EOF
#------------------------------------------------------------- localization settings
arch-chroot /mnt localectl set-keymap us
arch-chroot /mnt ln -sf /usr/share/zoneinfo/America/Los_Angeles /etc/localtime 
arch-chroot /mnt hwclock --systohc
rm /mnt/etc/locale.gen
echo 'en_US.UTF-8 UTF-8' >> /mnt/etc/locale.gen
arch-chroot /mnt locale-gen
echo 'LANG=en_US.UTF-8' >> /mnt/etc/locale.conf
echo 'LC_ALL=en_US.UTF-8' >> /mnt/etc/locale.conf 
echo 'KEYMAP=us' >> /mnt/etc/vconsole.conf
#------------------------------------------------------------- misc for root
cp /root/arch_install_scripts/*.service /mnt/etc/systemd/system/
cp /root/arch_install_scripts/rgb-server /mnt/usr/sbin/ 
cp /root/arch_install_scripts/hosts /mnt/etc/hosts
cp /root/arch_install_scripts/unison /mnt/usr/bin/
cp -r /root/arch_install_scripts /mnt/root/
chmod 777 /mnt/root/
chmod u+s /mnt/usr/bin/light
arch-chroot /mnt systemctl enable sshd
arch-chroot /mnt systemctl enable NetworkManager
arch-chroot /mnt systemctl enable vncserver0
arch-chroot /mnt systemctl enable bluetooth
#------------------------------------------------------------- add users
arch-chroot /mnt useradd -mG wheel,users,audio,lp,optical,storage,video,power,uucp,lock -s /bin/bash saveguest
arch-chroot /mnt useradd -m -s /bin/bash bioeuser0
arch-chroot /mnt useradd -m -s /bin/bash bioeuser1
arch-chroot /mnt useradd -m -s /bin/bash bioeuser2
echo ":9=saveguest" >> /mnt/etc/tigervnc/vncserver.users
rm /mnt/usr/share/xsessions/openbox-kde.desktop
# manual steps in arch-chroot:
# set the root password
# set the saveguess, bioeuser0, bioeuser1, bioeuser2 passwords
# su saveguest and vncpasswd
# EDITOR=nano visudo pick the NOPASSWD option
# exit the chroot and reboot into root account:
# su bioeuser0
# ssh-keygen
# ssh-copy-id he9-wan
# edit /etc/systemd/system/phone-home.service for port number
# systemctl daemon-reload
# systemctl enable phone-home
# reboot and then make sure phone home works by using be2 to reverse tunnel in
# login as saveguest and execute runme
