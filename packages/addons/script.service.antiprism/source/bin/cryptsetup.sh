#!/bin/ash

################################################################################
#  Copyright (C) AntiPrism.ca 2014
#  Based on the code created by Peter Smorada
#  Based on the code created by Stephan Raue (stephan@openelec.tv) and code
#  originally found in http://linux.sparsile.org/2009/09/automated-truecrypt-container-creation.html
#
#  This Program is free software; you can redistribute it and/or modify
#  it under the terms of the GNU General Public License as published by
#  the Free Software Foundation; either version 2, or (at your option)
#  any later version.
#
#  This Program is distributed in the hope that it will be useful,
#  but WITHOUT ANY WARRANTY; without even the implied warranty of
#  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
#  GNU General Public License for more details.
#
#  You should have received a copy of the GNU General Public License
#  along with OpenELEC.tv; see the file COPYING.  If not, write to
#  the Free Software Foundation, 51 Franklin Street, Suite 500, Boston, MA 02110, USA.
#  http://www.gnu.org/copyleft/gpl.html
################################################################################

# In case on modification to the script please redirect command output to stderr (>&2)
# otherwise you risk mallfunction of certain features of the python part.

mountdrive() {
	luksfile=$1
	drive=$2
	pass=$3
	keyfiles=$4
	filesystem=$5
	fs_options=$6

	[ -z "$pass" ] && read pass
	[ -z "$filesystem" ] && filesystem="ext4"
	suffix=""
	[ "$filesystem" = "none" ] || suffix="-`date +%s`"

	echo "$pass" | cryptsetup luksOpen $luksfile cryptsetup-antiprism"$suffix" >&2
        if [ "$?" != "0" ]; then
                echo "Container opening failed." >&2
                return 1
        fi

	[ "$filesystem" = "none" ] && return 0

	if [ -n "$fs_options " ]
	then
		mount -t "$filesystem" -o "$fs_options" /dev/mapper/cryptsetup-antiprism"$suffix" "$drive" >&2
	else
		mount -t "$filesystem" /dev/mapper/cryptsetup-antiprism"$suffix" "$drive" >&2
	fi
	
	# test if mounted sucessfully
	ismounted $luksfile $drive
	if [ $? -eq 0 ] && [ "$ANTIPRISM" = "1" ]; then
		mkdir -p "$drive/.hiawatha/docroot/cgi-bin" >&2
		mkdir -p "$drive/.hiawatha/logs" >&2
		mkdir -p "$drive/.hiawatha/data" >&2
		ln -s -f "$drive/.hiawatha/docroot/cgi-bin" "$drive/.hiawatha/cgi-bin" >&2
		[ -f "$drive/.hiawatha/hiawatha.conf" ] || sed -e "s|\$HOME|$drive|g" /etc/hiawatha/hiawatha.conf.tmpl > "$drive/.hiawatha/hiawatha.conf"
		[ -f "$drive/.hiawatha/cgi-wrapper.conf" ] || sed -e "s|\$HOME|$drive|g" /etc/hiawatha/cgi-wrapper.conf.tmpl > "$drive/.hiawatha/cgi-wrapper.conf"
		[ -f "$drive/.hiawatha/mimetype.conf" ] || cp /etc/hiawatha/mimetype.conf "$drive/.hiawatha/mimetype.conf" >&2
		chmod -R og-rx "$drive/.hiawatha" >&2
		mkdir -p "$drive/.keys" >&2
		if [ $? -eq 0 ]; then
			echo "$pass" | /usr/bin/ecc_key_gen "$drive/.keys/key_file.dat" >&2
		fi
		if [ -n "$ANTIPRISM_WRITE_FILE" ] && [ -n "$ANTIPRISM_WRITE_BUFFER" ]; then
			echo -e "$ANTIPRISM_WRITE_BUFFER" > "$ANTIPRISM_WRITE_FILE" 
		fi
		mkdir -p "$drive/.openvpn" >&2
		[ -f "$drive/.openvpn/secret.key" ] || openvpn --genkey --secret "$drive/.openvpn/static.key" >&2
		[ -f "$drive/.openvpn/config" ] || echo -e "dev tun\nifconfig 10.8.0.1 10.8.0.2\nsecret static.key\n" > "$drive/.openvpn/config"
		for f in /usr/lib/i2p/dist-plugins/plugins/*
		do 
			BN="`basename $f`"
			if ([ ! -d $drive/i2p/plugins/$BN ]) || ([ "`grep '^version=' $f/plugin.config`" != "`grep '^version=' $drive/i2p/plugins/$BN/plugin.config`" ]); then
				mkdir -p $drive/i2p/plugins >&2; cp -r -f $f/ $drive/i2p/plugins/ >&2
			fi
		done
		if [ "$ANTIPRISM_NOSSH" = "1" ]; then
			rm -rf /storage/.cache/ssh/password >/dev/null
		else
			if [ ! -f /storage/.cache/ssh/password ]; then
				read sshpass
				echo "$sshpass" | ecc_hashpassword /storage/.cache/ssh/password >&2
			fi
			if (test ! -d "$drive/.ssh") || (test ! -f "$drive/.ssh/ssh_host_key") || (test ! -f "$drive/.ssh/ssh_host_key.pub"); then
				rm -rf "$drive/.ssh"
				mkdir -p "$drive/.ssh"
 				/usr/bin/ssh-keygen -t rsa1 -f "$drive/.ssh/ssh_host_key" -N "" >&2
 				/usr/bin/ssh-keygen -t dsa -f "$drive/.ssh/ssh_host_dsa_key" -N "" >&2
 				/usr/bin/ssh-keygen -t rsa -f "$drive/.ssh/ssh_host_rsa_key" -N "" >&2
 				/usr/bin/ssh-keygen -t ed25519 -f "$drive/.ssh/ssh_host_ed25519_key" -N "" >&2
 				/usr/bin/ssh-keygen -t ecdsa -f "$drive/.ssh/ssh_host_ecdsa_key" -N "" >&2
 			fi
 			/usr/sbin/sshd \
 				-h "$drive/.ssh/ssh_host_key" \
 				-h "$drive/.ssh/ssh_host_dsa_key" \
 				-h "$drive/.ssh/ssh_host_rsa_key" \
 				-h "$drive/.ssh/ssh_host_ed25519_key" \
 				-h "$drive/.ssh/ssh_host_ecdsa_key" >&2
 			if test $? -ne 0; then exit 1; fi
		fi
		if [ -n "$ANTIPRISM_IPTABLES" ]; then
			echo -e "$ANTIPRISM_IPTABLES" | while read line; do iptables $line; done
		fi
		if [ -f "$drive/i2p/i2ptunnel.config" ]; then
			if [ "$ANTIPRISM_WEBSITE" = "1" ]; then
				sed -i "s#tunnel\.3\.startOnLoad\=false#tunnel.3.startOnLoad=true#g" "$drive/i2p/i2ptunnel.config" >&2
			else
				sed -i "s#tunnel\.3\.startOnLoad\=true#tunnel.3.startOnLoad=false#g" "$drive/i2p/i2ptunnel.config" >&2
			fi
		fi
	fi

	return $?
}

unmountdrive() {
	luksfile=$1
	drive=$2

	name=""
	[ -n "$drive" ] && name=`mount | grep "$drive" | cut -f 1 -d " " | cut -f 1 -d " " | cut -f 4 -d "/"`
	[ -z "$name" ] && name="cryptsetup-antiprism"

	if [ -n "$drive" ]
	then	
		# check for links and their usage in case they are found
		linkTest=$(readlink -f $drive) >&2
		if [ "${linkTest}" != "" ]; then
			echo "Provided mount point drive is a link. Using real folder instead of link." >&2
			drive=${linkTest}
		fi

		if [ "${drive#${drive%?}}" == "/" ]; then
			echo "Drive name ends in /. Removing last character." >&2
			drive=${drive%?}
		fi

		sshpid=`ps | grep /usr/sbin/sshd | grep -v grep | awk '{print $1}'`
		if test -n "$sshpid"; then for pid in $sshpid; do kill -9 $pid; done; fi
		
		if [ -n "$ANTIPRISM_IPTABLES" ]; then
			echo -e "$ANTIPRISM_IPTABLES" | while read line; do iptables $line; done
		fi
		umount "$drive" >&2
	fi
 
	cryptsetup luksClose "$name" >&2
	return $?
}

ismounted(){
	file=$1
	drive=$2
  
	mount | grep -q "$drive" >&2
	return $?
}

mkcontainer() {
	file=${1}
	drive=${2}
	pass=${3}
	SIZE=${4}
	filesys=${5}
	keyfiles=${6}

	[ -z "$pass" ] && read pass

	mkdir -p "$drive"
	[ -z "$filesys" ] && filesys="ext4"
	echo "Executing unmouning of the drive." >&2
	umount "$drive" >&2

	echo "Executing creation of the container." >&2
	let SIZE=SIZE/1048576+1
	dd if=/dev/zero count=${SIZE} bs=1048576 of="$file" >&2 && ( echo "$pass"; echo "$pass" ) | cryptsetup -q --cipher aes-xts-plain64 --key-size 512 --hash sha512 --use-urandom luksFormat "$file" >&2
	if [ "$?" != "0" ]; then
		echo "Container creation failed." >&2
		return 1
	fi

	mountdrive "$file" "" "$pass" "" "none"
	if [ "$?" != "0" ]; then
		echo "Mounting with no filesystem failed." >&2
		return 1
	fi
	
	echo "Formatting the container with $filesys." >&2
	mkfs.$filesys -L LUKS_VOLUME /dev/mapper/cryptsetup-antiprism >&2
	if [ "$?" != "0" ]; then
		echo "Formatting failed." >&2
		return 2
	fi

	sleep 2
	unmountdrive "$file"
	if [ "$?" != "0" ]; then
		echo "Unmounting failed." >&2
		return 3
	fi
	
	return 0
}

changepassword(){
	luksfile=$1
	oldpass=$2
	newpass=$3
	keyfiles="$4"

	[ -z "$oldpass" ] && read oldpass
	[ -z "$newpass" ] && read newpass

	echo "Executing truecrypt password change." >&2
	( echo $oldpass; echo $newpass; echo $newpass ) | cryptsetup luksChangeKey "$luksfile" >&2
  
	if [ "$?" != "0" ]; then
		echo "Password change failed." >&2
		return 1
	else
		"Password changed successfully." >&2
		return 0
	fi

}

createkeyfile(){
	echo "Key support for LUKS not implemented yet" >&2
	return 1	
}

checkdrive() {
	file=${1}
	pass=${2}
	fsystem=${3}
	options=${4}
	
	[ -z "$pass" ] && read pass

        mountdrive "$file" "" "$pass" "" "none"
        if [ "$?" != "0" ]; then
                echo "Mounting with no filesystem failed." >&2
                return 1
        fi

	mounted="/dev/mapper/cryptsetup-antiprism"
	echo "Checking $mounted..." >&2
	if [ -n "$fsystem" ]
	then
		fsck.$fsystem $options $mounted
	else
		fsck $mounted
	fi
	rv=$?

	unmountdrive "$file"
	if [ "$?" != "0" ]; then
		echo "Unmounting failed." >&2
		return 2
	fi

        return $rv
}

showinfo() {
	echo "Usage:" 
	echo "mount LUKS_FILE/PARTION MOUNT_POINT PASSWORD [KEY_FILES FILE_SYSTEM MNT_OPTIONS]"
	echo "dismount LUKS_FILE/PARTION MOUNT_POINT"
	echo "ismounted LUKS_FILE/PARTION MOUNT_POINT"
	echo "changepass LUKS_FILE/PARTION OLD_PASS NEW_PASS [KEY_FILES RANDOM_DATA_GENERATOR]"
	echo "create LUKS_FILE/PARTION MOUNT_POINT PASSWORD SIZE [FILE_SYSTEM KEY_FILES RANDOM_DATA_GENERATOR VOLUME_TYPE]"
	echo "createkey KEY_FILE [RANDOM_DATA_GENERATOR]"
	echo "check LUKS_FILE/PARTION PASSWORD [FILE_SYSTEM OPTIONS]"
}


case "$1" in
	mount) mountdrive "$2" "$3" "$4" "$5" "$6"
		rv=$?
		;;
	dismount) unmountdrive "$2" "$3" "$4"
		;;
	ismounted) ismounted "$2" "$3"
		rv=$?
		echo "EV:$rv"
		;;
	create) mkcontainer "$2" "$3" "$4" "$5" "$6" "$7" "$8"
		rv=$?
		;;
	format) format "$2" "$3" "$4" "$5"
		rv=$?
		echo "EV:$rv"
		;;
	changepass) changepassword "$2" "$3" "$4" "$5" "$6"
		rv=$?
		echo "EV:$rv"
		;;
	createkey) createkeyfile "$2" "$3"
		rv=$?
		echo "EV:$rv"
		;;
	check) checkdrive "$2" "$3" "$4" "$5"
		rv=$?
		;;
	*) showinfo
		rv=0
		;;
esac

exit $rv
