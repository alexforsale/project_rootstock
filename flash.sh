#!/bin/sh -x
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
RECOVERYIMAGE=~/temp/twrp-recovery.img

# Ubuntu tarball
ROOTFS="vivid-preinstalled-touch-armhf.tar.gz"

# Location of phablet system.img
SYSTEMIMAGE=$OUT/system.img

# check fastboot status
check_fastboot()
{
	checking fastboot availability
	if ! fastboot devices | grep -q fastboot; then
	echo "device not detected in fastboot"
	fi
	echo "rebooting to fastboot"
	reboot_fastboot
	
}

reboot_fastboot()
{
adb reboot bootloader
}

# flash boot image
flash_boot()
{
	check_fastboot
	fastboot flash boot $BOOTIMAGE
}

# rebooting into recovery
# since the compiled recovery.img can't flash the tarball
# we'll use twrp recovery for now
boot_recovery()
{
	fastboot boot $RECOVERYIMAGE

	# wait for adb to connect
	wait_adb()
	{
	echo "waiting for adb for 10 second"
	sleep 10
	}
	wait_adb
}

# flash ubuntu tarball and the system.img
flash_ubuntu()
{
	if ! adb devices | grep -c device = 2; then
	wait_adb

	./rootstock-touch-install "$ROOTFS" "$OUT/system.img"
	fi
}

echo "flashing boot image"
flash_boot

echo "rebooting into recovery image"
boot_recovery

echo "flashing ubuntu"
if ! adb devices | grep -c device = 2; then
flash_ubuntu
fi
