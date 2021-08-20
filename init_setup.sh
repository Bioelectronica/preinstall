#!/bin/sh

pacman -S git
pacman -S glibc
pacman git clone https://github.com/Bioelectronica/arch_install_scripts
cd arch_install_scripts
sh uni.sh
arch-chroot /mnt
echo 'welcome passwod'
passwd
echo 'welcome password'
passwd saveguest

