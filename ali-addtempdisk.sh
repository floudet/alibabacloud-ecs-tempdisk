#!/bin/bash
export PATH=$PATH:/usr/local/bin/:/usr/bin

# Adds or removes a temporary disk to an Aliyun ECS instance
# This script assumes that:
# * aliyun-cli is installed and configured
# * instance_name is the same as hostname 
#
# Author: Fabien Loudet

DISKSIZE=50
REMOVEID=''

random-string()
{
  UUID=$(cat /proc/sys/kernel/random/uuid)
  LENGTH=${1:-36}
  echo ${UUID:0:$LENGTH}
}

getInstanceName()
{
  local instance_name=$(/bin/hostname)
  echo ${instance_name}
}

getInstanceId()
{
  instance_id=$(aliyun ecs DescribeInstances --InstanceName $(getInstanceName) | egrep -Eow 'InstanceId":"([^"]*)"' | cut -d":" -f 2 | tr -d '"')

  echo ${instance_id}
}

getInstanceRegion()
{
  instance_region=$(aliyun ecs DescribeInstances --InstanceName $(getInstanceName) | egrep -Eow 'RegionId":"([^"]*)"' | cut -d":" -f 2 | tr -d '"')

  echo ${instance_region}
}

getInstanceZone()
{
  instance_zone=$(aliyun ecs DescribeInstances --InstanceName $(getInstanceName) | egrep -Eow 'ZoneId":"([^"]*)"' | cut -d":" -f 2 | tr -d '"') 

  echo ${instance_zone}
}

createDisk()
{
  new_disk_id=$(aliyun ecs CreateDisk --RegionId $(getInstanceRegion) --ZoneId $(getInstanceZone) --DiskName $1 --Size $DISKSIZE --DiskCategory cloud_efficiency | egrep -Eow 'DiskId":"([^"]*)"' | cut -d":" -f 2 | tr -d '"')

  echo ${new_disk_id}
}

getDiskStatus()
{
  json_disk_id="[\"$1\"]"

  disk_status=$(aliyun ecs DescribeDisks --RegionId $(getInstanceRegion) --DiskIds $json_disk_id | egrep -Eow 'Status":"([^"]*)"' | cut -d":" -f 2 | tr -d '"')

  echo ${disk_status}
}

getDeviceFile()
{
  json_device_id="[\"$1\"]"

  device_file=$(aliyun ecs DescribeDisks --RegionId $(getInstanceRegion) --DiskIds $json_device_id | egrep -Eow 'Device":"([^"]*)"' | cut -d":" -f 2 | tr -d '"')

  echo ${device_file}
}

getDiskInstance()
{
  json_device_id="[\"$1\"]"

  disk_instance=$(aliyun ecs DescribeDisks --RegionId $(getInstanceRegion) --DiskIds $json_device_id | egrep -Eow 'Device":"([^"]*)"' | cut -d":" -f 2 | tr -d '"')

  echo ${disk_instance}
}

checkDisk()
{
  json_disk_id="[\"$1\"]"
  found=0
  total_count=$(aliyun ecs DescribeDisks --RegionId $(getInstanceRegion) --DiskIds $json_disk_id | grep -Po '"TotalCount":\d' | cut -d':' -f2) 
  if [[ $total_count == 1 ]];then
    found=1
  fi
  echo ${found}
}

addDisk()
{
  TEMP="temp-$(random-string 8)"

  DISK_ID=$(createDisk $TEMP)

  DISK_STATUS=''
  while [ "$DISK_STATUS" != "Available" ]; do
    DISK_STATUS=$(getDiskStatus $DISK_ID)
    sleep 2 
  done

  OUTPUT_ATTACH_DISK=$(aliyun ecs AttachDisk --InstanceId $(getInstanceId) --DiskId $DISK_ID)

  DEVICE_FILE=''
  while [ "x$DEVICE_FILE" = "x" ]; do
    DEVICE_FILE=$(getDeviceFile $DISK_ID | tr -d 'x')
    sleep 2
  done

  OUTPUT_MKFS=$(mkfs.xfs $DEVICE_FILE)

  mkdir /mnt/$TEMP

  mount $DEVICE_FILE /mnt/$TEMP

  echo "DiskId: $DISK_ID"
  echo "Device: $DEVICE_FILE"
  echo "Mount Point: /mnt/$TEMP"
}

removeDisk()
{
  DISKEXISTS=$(checkDisk $1)
  if [[ $DISKEXISTS == 1 ]];then
    DEVICE_FILE=$(getDeviceFile $1 | tr -d 'x')
    MOUNT_POINT=$(grep $DEVICE_FILE /proc/mounts | cut -d ' ' -f 2)
    REGEXP='^\/mnt\/temp-[a-z0-9]{8}'
    if [[ ! $MOUNT_POINT =~ $REGEXP ]] ; then
      echo "Error: Not a temp Disk, cowardly refusing to proceed any further."
      exit -1
    fi
    umount $DEVICE_FILE
    OUTPUT_DETACH_DISK=$(aliyun ecs DetachDisk --InstanceId $(getInstanceId) --DiskId $1)
    sleep 2
    OUTPUT_DELETEDISK_DISK=$(aliyun ecs DeleteDisk --DiskId $1)
    rmdir $MOUNT_POINT
    DISKEXISTS=$(checkDisk $1)
    if [[ $DISKEXISTS == 1 ]];then
      echo "Error: Something went wrong"
      exit -1
    else
      echo "Disk removed successfully"
    fi
  else
    echo "Error: Disk with id '$1' could not be found"
    exit -1
  fi
}

usage() 
{
  echo "Usage: $0 [ -s DISKSIZE ] | [ -r DISKID ]"
  echo "    -s [Disk Size]   * Disk Size in GB (Default: 50)"
  echo "    -r [Disk Id]     * Disk ID to remove"
  exit 0
}

if [ $# -eq 0 ]; then usage; fi
if [ "$1" == "--help" ]; then usage; fi

while getopts s:r: ARG
do
  case "$ARG" in
    s)
      DISKSIZE=$OPTARG
      addDisk
      ;;
    r)
      REMOVEID=$OPTARG
      removeDisk $REMOVEID
      ;;
    *)
    echo "???"
    usage
    exit -1
  esac
done

exit 0
