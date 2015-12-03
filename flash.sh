#!/bin/sh
#
#
#  Author: Christian Alexander <alexforsale@yahoo.com>
#  This program is free software; you can redistribute it and/or
#  modify it under the terms of the GNU General Public License as
#  published by the Free Software Foundation; either version 2 of the
#  License, or (at your option) any later version.
#
#  This program is distributed in the hope that it will be useful,
#  but WITHOUT ANY WARRANTY; without even the implied warranty of
#  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#  GNU General Public License for more details.
#
#  You should have received a copy of the GNU General Public License
#  along with this program; if not, write to the Free Software
#  Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA 02111-1307
#  USA
#

# Location of phablet boot.img
BOOTIMAGE=$OUT/boot.img

# Location of twrp recovery.img
RECOVERYIMAGE=recovery.img

# Ubuntu tarball
VERSION="saucy"
ROOTFS="$VERSION-preinstalled-touch-armhf.tar.gz"

# Location of phablet system.img
SYSTEMIMAGE=$OUT/system.img

check_prereq()
{
	if [ ! $(which make_ext4fs) ] || [ ! -x $(which simg2img) ] || \
		[ ! -x $(which adb) ]; then
		echo -e ' \t ' "please install the android-tools-fsutils and android-tools-adb packages" && exit 1
	fi
}

# check files
check_files()
{
	echo "checking boot.img"
	if [ ! -e "$BOOTIMAGE" ]; then
	    echo ' \t ' "boot image not detected, this script needs to be run under android build environment"
	    echo ' \t ' "and after the android compilation process completed."
	    echo ' \t ' "if you want to used precompiled boot.img, please put it in this folder as boot.img"
		if [ -e boot.img ]; then
		echo ' \t\t ' "using precompiled boot.img"
		BOOTIMAGE=boot.img
		else
		echo ' \t ' "boot.img not found, aborting"
		exit 1
		fi
	fi
	echo "boot image available:$BOOTIMAGE"
	echo

	echo "checking recovery.img"
	if [ ! -e "$RECOVERYIMAGE" ]; then
	    echo ' \t ' "recovery image not detected"
	    echo ' \t ' "right now the recovery image from the build tree still not working"
	    echo ' \t ' "in the mean time, please use the latest recovery image from twrp for redmi 1s"
	    echo ' \t ' "and put it in this folder as recovery.img"
		if [ -e recovery.img ]; then
		echo ' \t\t ' "using precompiled recovery.img"
		RECOVERYIMAGE=recovery.img
		else
		echo ' \t ' "recovery.img not found, aborting"
		exit 1
		fi
	fi
	echo "recovery image available:$RECOVERYIMAGE"
	echo

	echo "checking system.img"
	if [ ! -e "$SYSTEMIMAGE" ]; then
	    echo ' \t ' "system image not detected, please make sure the android build process completed without"
	    echo ' \t ' "any errors, if you want to used precompiled system.img, "
	    echo ' \t ' "please put it in this folder as system.img"
		if [ -e system.img ]; then
		echo ' \t\t ' "using precompiled system.img"
		SYSTEMIMAGE=system.img
		else
		echo ' \t ' "system.img not found, aborting"
		exit 1
		fi
	fi
	echo "system image available:$SYSTEMIMAGE"
	echo

	echo "checking Ubuntu tarball"
	if [ ! -e "$ROOTFS" ]; then
	    echo ' \t ' "Ubuntu tarball not detected"
	    echo ' \t ' "we're currently using Ubuntu $VERSION please download $VERSION-preinstalled-touch-armhf.tar.gz"
	    	if [ "$VERSION" = "saucy" ] ; then
		    echo ' \t ' "from http://cdimage.ubuntu.com/ubuntu-touch/saucy/daily-preinstalled/20131127/"
	    	elif [ "$VERSION" = "vivid" ] ; then
	    	    echo ' \t ' "from http://cdimage.ubuntu.com/ubuntu-touch/vivid/daily-preinstalled/current/"
	    	else
	    	    echo ' \t ' "from http://cdimage.ubuntu.com/ubuntu-touch/daily-preinstalled/current/"
	    	fi
	    echo ' \t ' "and put it in this folder"
	    exit 1
	fi

	echo "using Ubuntu tarball $ROOTFS"
	echo
}

copy_overlays()
{
	source=$OUT/system/ubuntu
	target=$PWD/configs

	rm -rf $target/*
	mkdir -p configs
	
	OLD_PWD=$PWD
		cd $source
		for overlaydirs in `find . -type d ` ; do
			mkdir -p $target/$overlaydirs
		done

		for overlay in `find . -type f` ; do
			[ -f ${target}/${overlay} ] 
			cp ${overlay} ${target}/${overlay}
		done
	cd $OLD_PWD
}

check_device()
{
	if [ $(adb devices | grep -cw device) -eq 1 ] || [ $(adb devices | grep -cw recovery) -eq 1 ]; then
	echo "device detected"
	else
	echo "device not detected, aborting"
	exit 1	
	fi
}

reboot_fastboot()
{
	adb reboot bootloader >/dev/null 2>&1
}

# flash boot image
flash_boot()
{
	fastboot flash boot $BOOTIMAGE >/dev/null 2>&1
	echo "done"
}

# rebooting into recovery
# since the compiled recovery.img can't flash the tarball
# we'll use twrp recovery for now
wait_for_adb()
{
	while [ $(adb devices | grep -cw device) -eq 0 ]
	do
	    echo "waiting adb for 10s"
	    sleep 10
	done 
}
boot_recovery()
{
	fastboot boot $RECOVERYIMAGE >/dev/null 2>&1
	wait_for_adb
	echo "done"
}

# flash ubuntu tarball and the system.img
flash_ubuntu()
{
	./rootstock-touch-install "$ROOTFS" "$OUT/system.img"
}
echo "checking device availability"
check_device

echo "list all needed files"
check_prereq
check_files

echo "copying overlays from the build dirs"
copy_overlays

echo "checking device availability"
check_device

echo "flashing boot image"
reboot_fastboot
flash_boot

echo "rebooting into recovery image"
boot_recovery

echo "flashing ubuntu"
flash_ubuntu

