#!/bin/bash
getntfsVol ()
{
	diskinfo="$(diskutil info "$1")"
	ntfs="$(echo ${diskinfo} | grep NTFS)"
	volumename=""
	if [[ -n "$ntfs" ]]; then
		 volumename=`echo ${diskinfo#*Mount\ Point\:}`
		 volumename=`echo ${volumename%Partition\ Type\:*}`
		 echo $volumename
	fi
}

DEVCOUNT=0
NTFSCOUNT=0
MOUNTCOUNT=0

sudo echo "checking the ntfs partition..."
devs=`df | grep /Volumes/ | awk '{print $1}'`
while read dev
do
	DEVCOUNT=$(($DEVCOUNT + 1))
	VolName="$(getntfsVol "$dev")"
	if [[ -z "$VolName" ]]; then
		continue	
	fi
	echo "found ntfs partition: ${VolName} on ${dev}."
	NTFSCOUNT=$(($NTFSCOUNT + 1))
	diskutil umount ${dev} > /dev/null 2>&1
	if [[ $? -ne 0 ]] ; then
		echo "unmount failed for ${dev}, stopped verifying"
		continue
	fi
	sudo mkdir "${VolName}"
	sudo mount -t ntfs -o rw,auto,nobrowse ${dev} "${VolName}" > /dev/null 2>&1
	if [[ $? -ne 0 ]] ; then
		sudo umount ${dev} > /dev/null 2>&1
		sudo rm -fr "${VolName}" > /dev/null 2>&1
		echo "mount failed for ${dev}, need to repair in windows PC."
		echo "mount Read-only file system for ${dev}, mount on ${VolName}."
		diskutil mount ${dev} 
	else
		MOUNTCOUNT=$(($MOUNTCOUNT + 1))
		ln -s -f "${VolName}" ~/Desktop > /dev/null 2>&1
		echo "mount succeed for ${dev}, mount on ${VolName}."
		open ${VolName}
	fi
done <<< "$devs"
if [[ $MOUNTCOUNT -gt 0 ]]; then
	open /Volumes
fi
echo "Ext:${DEVCOUNT}, Ntfs:${NTFSCOUNT}, Succeed:${MOUNTCOUNT}."
