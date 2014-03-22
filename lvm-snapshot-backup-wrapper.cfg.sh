## $Id: lvm-snapshot-backup-wrapper.cfg.sh,v 1.2 2009/05/27 12:16:23 wschlich Exp wschlich $
## vim:ts=4:sw=4:tw=200:nu:ai:nowrap:
##
## Created by Wolfram Schlich <wschlich@gentoo.org>
## Licensed under the GNU GPLv3
##

##
## application settings
##

## directory under which the system mirror is being mounted
export SystemMirrorMountDirectory="/mnt/sysmirror"

## -- lvm-snaptool settings --

## path to lvm-snaptool
export LvmSnapTool="/usr/sbin/lvm-snaptool.sh"

## arguments for system mirror create/delete
export LvmSnapToolSystemMirrorCreateArgs=""
export LvmSnapToolSystemMirrorDeleteArgs=""

## example arguments:
## - specify snapshot volume size factor:
##   - default: 0.2
##   - for LV vgs/lvhome: 0.3
##   - for LV vgs/lvusr: 0.1
## - exclude LV vgs/lvtmp
#export LvmSnapToolSystemMirrorCreateArgs="-f 0.2,vgs/lvhome:0.3,vgs/lvusr:0.1 -e vgs/lvtmp"

## custom pre/post commands
export SystemMirrorCreatePreExecCommand=
export SystemMirrorCreatePostExecCommand=
export SystemMirrorDeletePreExecCommand=
export SystemMirrorDeletePostExecCommand=

## example pre/post commands for mysql backup:
#export SystemMirrorCreatePreExecCommand="/local/adm/mysql-backup/mysql-backup-split.sh -d /local/backup/mysql/sysmirror -r -A -T -c"
#export SystemMirrorDeletePostExecCommand="rm -rf /local/backup/mysql/sysmirror"

## -- rdiff-backup settings --

## absolute path to rdiff-backup
export RdiffBackup="/usr/bin/rdiff-backup"

## -- rsnapshot settings (uses rsync) --

## absolute path to rsync
export Rsync="/usr/bin/rsync"

## arguments for rsync
## set these to match the rsync arguments in your rsnapshot.conf
export RsyncArgs="-vlogDtpAXrRSe.iLs --numeric-ids"
