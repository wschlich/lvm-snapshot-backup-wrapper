#!/bin/bash
## vim:ts=4:sw=4:tw=200:nu:ai:nowrap:
##
## lvm-snapshot-backup-wrapper: A wrapper script for creating system backups with lvm-snaptool.sh and rdiff-backup/rsnapshot
##
## Created by Wolfram Schlich <wschlich@gentoo.org>
## Licensed under the GNU GPLv3
## Web: http://www.bashinator.org/projects/lvm-snapshot-backup-wrapper/
## Code: https://github.com/wschlich/lvm-snapshot-backup-wrapper/
##

##
## NOTES
## =====
## - you have to run 'bash -O extglob -O extdebug -n thisscriptfile' to test this script!
##

##
## bashinator basic variables
##

export __ScriptFile=${0##*/} # evaluates to "lvm-snaptoo.sh"
export __ScriptName=${__ScriptFile%.sh} # evaluates to "lvm-snapshot-backup-wrapper"
export __ScriptPath=${0%/*}; __ScriptPath=${__ScriptPath%/} # evaluates to /path/to/lvm-snapshot-backup-wrapper/lvm-snapshot-backup-wrapper.sh
export __ScriptHost=$(hostname -f) # evaluates to the current hostname, e.g. host.example.com

##
## bashinator library and config
##

## system installation of bashinator (and application):
##
## /etc/lvm-snapshot-backup-wrapper/bashinator.cfg.sh
## /usr/share/bashinator/bashinator.lib.0.sh
##
## accepting overrides using user-defined environment variables:
export __BashinatorConfig="${__BashinatorConfig:-/etc/${__ScriptName}/bashinator.cfg.sh}"
export __BashinatorLibrary="${__BashinatorLibrary:-/usr/share/bashinator/bashinator.lib.0.sh}" # APIv0
##
## not accepting overrides (for security reasons):
#export __BashinatorConfig="/etc/${__ScriptName}/bashinator.cfg.sh"
#export __BashinatorLibrary="/usr/share/bashinator/bashinator.lib.0.sh" # bashinator API v0

## local installation of bashinator and application in dedicated script path:
##
## /path/to/lvm-snapshot-backup-wrapper/bashinator.cfg.sh
## /path/to/lvm-snapshot-backup-wrapper/bashinator.lib.0.sh
##
#export __BashinatorConfig="${__ScriptPath}/bashinator.cfg.sh"
#export __BashinatorLibrary="${__ScriptPath}/bashinator.lib.0.sh" # bashinator API v0

## include required source files
if ! source "${__BashinatorConfig}"; then
    echo "!!! FATAL: failed to source bashinator config '${__BashinatorConfig}'" 1>&2
    exit 2
fi
if ! source "${__BashinatorLibrary}"; then
    echo "!!! FATAL: failed to source bashinator library '${__BashinatorLibrary}'" 1>&2
    exit 2
fi

##
## boot bashinator:
## - if configured, it can check for a minimum required bash version
## - if configured, it can enforce a safe PATH
## - if configured, it can enforce a specific umask
## - it enables required bash settings (e.g. extglob, extdebug)
##

__boot

##
## application library and config
##

## system installation of application config and library
##
## /etc/lvm-snapshot-backup-wrapper/lvm-snapshot-backup-wrapper.cfg.sh
## /usr/share/lvm-snapshot-backup-wrapper/lvm-snapshot-backup-wrapper.lib.sh
##
## accepting overrides using user-defined environment variables:
export ApplicationConfig="${ApplicationConfig:-/etc/${__ScriptName}/${__ScriptName}.cfg.sh}"
export ApplicationLibrary="${ApplicationLibrary:-/usr/share/${__ScriptName}/${__ScriptName}.lib.sh}"
##
## not accepting overrides (for security reasons)
#export ApplicationConfig="/etc/${__ScriptName}/${__ScriptName}.cfg.sh"
#export ApplicationLibrary="/usr/share/${__ScriptName}/${__ScriptName}.lib.sh"

## local installation of application config and library in dedicated script path:
##
## /path/to/lvm-snapshot-backup-wrapper/lvm-snapshot-backup-wrapper.cfg.sh
## /path/to/lvm-snapshot-backup-wrapper/lvm-snapshot-backup-wrapper.lib.sh
##
#export ApplicationConfig="${__ScriptPath}/${__ScriptName}.cfg.sh"
#export ApplicationLibrary="${__ScriptPath}/${__ScriptName}.lib.sh"

## include required source files (using bashinator functions with builtin error handling)
__requireSource "${ApplicationConfig}"
__requireSource "${ApplicationLibrary}"

##
## dispatch the application with all original command line arguments
##

__dispatch "${@}"
