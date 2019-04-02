# Adds or removes a temporary disk to an Alibaba Cloud (aliyun) ECS instance

Automation script for Aliyun Elastic Compute Service:
- Add (create, attach, formats, mount) a temporary disk to the calling instance
- Removes (unmount, detach, delete) a temporary disk created with the script

## Usage
```
Usage: /usr/local/scripts/ali-addtempdisk.sh [ -s DISKSIZE ] | [ -r DISKID ]
    -s [Disk Size]   * Disk Size in GB (Default: 50)
    -r [Disk Id]     * Disk ID to remove
```

## Prerequisites
* [aliyun-cli](https://github.com/aliyun/aliyun-cli) must be installed and configured
* The script assumes that the `instance name` is the same as the hostname
* The new disk is formatted using XFS, make sure the xfsprogs package is installed

## Installation

ssh on to the server on which you temporarily need extra space

**Install Script**: Download the latest version of the script and make it executable:
```
cd ~
wget https://raw.githubusercontent.com/floudet/alibabacloud-ecs-tempdisk/master/ali-addtempdisk.sh
chmod +x ali-addtempdisk.sh
sudo mkdir -p /opt/alibabacloud-ecs-tempdisk
sudo mv ali-addtempdisk.sh /opt/alibabacloud-ecs-tempdisk/
```

## Use cases
Any task for which you temporarily need some extra space (backup recovery, etc). 

## Add a new disk
By default the script will add a 50G disk, however you can specify the size you want, by using the -s flag:

    Usage: ./ali-addtempdisk.sh [-s <disksize>]
    
    Options:
    
       -s  Disk Size in GB (Default: 50)

## Remove a disk
Use the -r flag to remove a disk that was previously added by the script. Take note that all the data present on the disk will be irremediably lost. 

    Usage: ./ali-addtempdisk.sh [-r <diskid>]
    
    Options:
    
       -r  Disk ID to remove

## Output samples

```
root@tianhe-2:~# /opt/alibabacloud-ecs-tempdisk/ali-addtempdisk.sh -s 80
DiskId: d-2zehwnc0zv4tmn6benia
Device: /dev/vdd
Mount Point: /mnt/temp-c0baecf0
You have mail in /var/mail/root
root@tianhe-2:~# mount | grep vdd
/dev/vdd on /mnt/temp-c0baecf0 type xfs (rw,relatime,attr2,inode64,noquota)
root@tianhe-2:~# /opt/alibabacloud-ecs-tempdisk/ali-addtempdisk.sh -r d-2zehwnc0zv4tmn6benia
Disk removed successfully
```

## License

MIT License

Copyright (c) 2019 Fabien Loudet

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
