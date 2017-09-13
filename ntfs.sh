#!/bin/bash

getNtfsVolName ()
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

sudo echo "检测ntfs分区..."
devs=`df | grep /Volumes/ | awk '{print $1}'`
while read dev
do
	DEVCOUNT=$(($DEVCOUNT + 1))
	
	VolName="$(getNtfsVolName "$dev")"
	if [[ -z "$VolName" ]]; then
		continue	
	fi
	echo "发现NTFS分区: ${dev}, 挂载点:${VolName}."
	NTFSCOUNT=$(($NTFSCOUNT + 1))
	diskutil umount ${dev}
	if [[ $? -ne 0 ]] ; then
		echo "弹出失败,请确定分区没有操作."
		continue
	fi
	
	sudo mkdir "${VolName}"
	sudo mount -t ntfs -o rw,auto,nobrowse ${dev} "${VolName}"
	if [[ $? -ne 0 ]] ; then
		sudo umount ${dev} > /dev/null 2>&1
		sudo rm -fr "${VolName}" > /dev/null 2>&1
		echo "分区:${dev}挂载写权限失败, 需要在windows修复."
		echo "只读挂载分区:${dev}, 挂载点:${VolName}."
		diskutil mount ${dev} 
	else
		MOUNTCOUNT=$(($MOUNTCOUNT + 1))
		ln -s -f "${VolName}" ~/Desktop > /dev/null 2>&1
		echo "成功挂载写权限分区:${dev}, 挂载点:${VolName}."
	fi
	
done <<< "$devs"
if [[ $MOUNTCOUNT -gt 0 ]]; then
	open /Volumes
fi
echo "扩展分区:${DEVCOUNT}个, NTFS分区:${NTFSCOUNT}个, 成功挂载:${MOUNTCOUNT}."