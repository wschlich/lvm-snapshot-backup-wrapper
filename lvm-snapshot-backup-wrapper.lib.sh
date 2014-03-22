## $Id: lvm-snapshot-backup-wrapper.lib.sh,v 1.2 2009/05/27 12:17:11 wschlich Exp wschlich $
## vim:ts=4:sw=4:tw=200:nu:ai:nowrap:
##
## Created by Wolfram Schlich <wschlich@gentoo.org>
## Licensed under the GNU GPLv3
##

##
## REQUIRED PROGRAMS
## =================
## - lvm-snaptool.sh
## - mktemp
## - touch
## - rm
##

##
## application control functions
##

function __init() {

	return 0 # success

} # __init()

function __main() {

	## initialize variables
	local -i Error=0
	local -i Fatal=0
	local -i SystemMirrorCreatedSuccessfully=0
	local -i SystemMirrorCreatePreExecCommandRanSuccessfully=0
	local -i SystemMirrorCreatePostExecCommandRanSuccessfully=0
	local -i SystemBackupFinishedSuccessfully=0
	local -i SystemMirrorDeletedSuccessfully=0
	local -i SystemMirrorDeletePreExecCommandRanSuccessfully=0
	local -i SystemMirrorDeletePostExecCommandRanSuccessfully=0

	## run system mirror create pre-exec command (if set)
	if [[ -n ${SystemMirrorCreatePreExecCommand} ]]; then
		__msg info "running system mirror create pre-exec command"
		if ! eval ${SystemMirrorCreatePreExecCommand} &>"${_L}"; then
			__msg err "failed running system mirror create pre-exec command"
			let Fatal=1
		else
			__msg info "successfully ran the system mirror create pre-exec command"
			let SystemMirrorCreatePreExecCommandRanSuccessfully=1
		fi
	fi

	## create system mirror when system mirror create pre-exec command ran successfully (if set)
	if [[ -z ${SystemMirrorCreatePreExecCommand} || ${SystemMirrorCreatePreExecCommandRanSuccessfully} -eq 1 ]]; then
		__msg info "creating system mirror"
		if ! createSystemMirror; then
			__msg err "failed to create system mirror"
			let Fatal=1
		else
			__msg info "successfully created the system mirror"
			let SystemMirrorCreatedSuccessfully=1
		fi
	fi

	## run system mirror create post-exec command (if set) when system mirror was created successfully
	if [[ ${SystemMirrorCreatedSuccessfully} -eq 1 && -n ${SystemMirrorCreatePostExecCommand} ]]; then
		__msg info "running system mirror create post-exec command"
		if ! eval ${SystemMirrorCreatePostExecCommand} &>"${_L}"; then
			__msg err "failed running system mirror create post-exec command"
			let Fatal=1
		else
			__msg info "successfully ran the system mirror create post-exec command"
			let SystemMirrorCreatePostExecCommandRanSuccessfully=1
		fi
	fi

	## run requested backup tool in server mode when system mirror was created successfully
	## and system mirror create post-exec command ran successfully (if set)
	if [[ ${SystemMirrorCreatedSuccessfully} -eq 1 && \
		( -z ${SystemMirrorCreatePostExecCommand} || ${SystemMirrorCreatePostExecCommandRanSuccessfully} -eq 1 ) ]]; then

		## check original command to determine requested backup tool
		BackupCommand="${SSH_ORIGINAL_COMMAND}"
		case "${BackupCommand}" in

			## rsnapshot/rsync
			rsync[[:space:]]--server[[:space:]]--sender[[:space:]]*)
				__msg info "running rsync"
				if ! runRsync; then
					__msg err "failed running rsync"
					let Error=1
				else
					__msg info "successfully ran rsync"
					let SystemBackupFinishedSuccessfully=1
				fi
				;;

			## rdiff-backup
			rdiff-backup[[:space:]]*)
				__msg info "running rdiff-backup"
				if ! runRdiffBackup; then
					__msg err "failed running rdiff-backup"
					let Error=1
				else
					__msg info "successfully ran diff-backup"
					let SystemBackupFinishedSuccessfully=1
				fi
				;;

			## invalid backup command
			*)
				__msg err "invalid backup command: '${BackupCommand}'"
				let Error=1
				;;

		esac

	fi

	## run system mirror delete pre-exec command (if set)
	if [[ -n ${SystemMirrorDeletePreExecCommand} ]]; then
		__msg info "running system mirror delete pre-exec command"
		if ! eval ${SystemMirrorDeletePreExecCommand} &>"${_L}"; then
			__msg err "failed running system mirror delete pre-exec command"
			let Fatal=1
		else
			__msg info "successfully ran the system mirror delete pre-exec command"
			let SystemMirrorDeletePreExecCommandRanSuccessfully=1
		fi
	fi

	## delete system mirror when system mirror delete pre-exec command ran successfully (if set)
	if [[ -z ${SystemMirrorDeletePreExecCommand} || ${SystemMirrorDeletePreExecCommandRanSuccessfully} -eq 1 ]]; then
		__msg info "deleting system mirror"
		if ! deleteSystemMirror; then
			__msg err "failed to delete the system mirror"
			let Fatal=1
		else
			__msg info "successfully deleted the system mirror"
			let SystemMirrorDeletedSuccessfully=1
		fi
	fi

	## run system mirror delete post-exec command (if set) when system mirror was deleted successfully
	if [[ ${SystemMirrorDeletedSuccessfully} -eq 1 && -n ${SystemMirrorDeletePostExecCommand} ]]; then
		__msg info "running system mirror delete post-exec command"
		if ! eval ${SystemMirrorDeletePostExecCommand} &>"${_L}"; then
			__msg err "failed running system mirror delete post-exec command"
			let Fatal=1
		else
			__msg info "successfully ran the system mirror delete post-exec command"
			let SystemMirrorDeletePostExecCommandRanSuccessfully=1
		fi
	fi

	## check for fatal errors
	if [[ ${Fatal} -gt 0 ]]; then
		__die 2 "a fatal error occured, please check preceding log entries for details"
	fi

	## check for non-fatal errors (remove the lockfile before exiting)
	if [[ ${Error} -gt 0 ]]; then
		rm -f "${__ScriptLockFile}" >&/dev/null # TODO FIXME
		__die 2 "a non-fatal error occured, please check preceding log entries for details"
	fi

	__msg info "finished successfully"

} # __main()

##
## application worker functions
##

function createSystemMirror() {

	## ----- head -----
	##
	## DESCRIPTION:
	##   creates a mirror of all mounted volumes using lvm-snaptool.sh
	##
	## ARGUMENTS:
	##   /
	##
	## GLOBAL VARIABLES USED:
	##   _L
	##   LvmSnapTool
	##   LvmSnapToolSystemMirrorCreateArgs
	##   SystemMirrorMountDirectory
	##

	## ----- main -----

	"${LvmSnapTool}" -q -M -d "${SystemMirrorMountDirectory}" ${LvmSnapToolSystemMirrorCreateArgs} -C >>"${_L}" 2>&1
	local -i lvmSnapToolExitCode=${?}
	if [[ ${lvmSnapToolExitCode} -ne 0 ]]; then
		__msg err "failed running lvm-snaptool (exit code: ${lvmSnapToolExitCode})"
		return 2 # error
	fi

	return 0 # success

} # createSystemMirror()

function deleteSystemMirror() {

	## ----- head -----
	##
	## DESCRIPTION:
	##   deletes a mirror of all mounted volumes using lvm-snaptool.sh
	##
	## ARGUMENTS:
	##   /
	##
	## GLOBAL VARIABLES USED:
	##   _L
	##   LvmSnapTool
	##   LvmSnapToolSystemMirrorDeleteArgs
	##   SystemMirrorMountDirectory
	##

	## ----- main -----

	"${LvmSnapTool}" -q -M -d "${SystemMirrorMountDirectory}" -D ${LvmSnapToolSystemMirrorDeleteArgs} >>"${_L}" 2>&1
	local -i lvmSnapToolExitCode=${?}
	if [[ ${lvmSnapToolExitCode} -ne 0 ]]; then
		__msg err "failed running lvm-snaptool (exit code: ${lvmSnapToolExitCode})"
		return 2 # error
	fi

	return 0 # success

} # deleteSystemMirror()

function runRdiffBackup() {

	## ----- head -----
	##
	## DESCRIPTION:
	##   runs rdiff-backup in server mode
	##
	## ARGUMENTS:
	##   /
	##
	## GLOBAL VARIABLES USED:
	##   SystemMirrorMountDirectory
	##   RdiffBackup
	##

	## ----- main -----

	## run rdiff-backup chrooted inside system mirror
	/usr/bin/chroot "${SystemMirrorMountDirectory}" "${RdiffBackup}" --server --restrict-read-only /
	local -i rdiffBackupExitCode=${?}
	if [[ ${rdiffBackupExitCode} > 0 ]]; then
		__msg err "failed running rdiff-backup (exit code: ${rdiffBackupExitCode})"
		return 2 # error
	fi

	return 0 # success

} # runRdiffBackup()

function runRsync() {

	## ----- head -----
	##
	## DESCRIPTION:
	##   runs rsync in server mode
	##
	## ARGUMENTS:
	##   /
	##
	## GLOBAL VARIABLES USED:
	##   SystemMirrorMountDirectory
	##   Rsync
	##   RsyncArgs
	##

	## ----- main -----

	## run rsync chrooted inside system mirror
	/usr/bin/chroot "${SystemMirrorMountDirectory}" "${Rsync}" --server --sender ${RsyncArgs} . /
	local -i rsyncExitCode=${?}
	case ${rsyncExitCode} in
		0)
			;;
		24)
			__msg notice "rsync reported vanished source files during transfer, continuing"
			;;
		*)
			__msg err "failed running rsync (exit code: ${rsyncExitCode}"
			return 2 # error
			;;
	esac

	return 0 # success

} # runRsync()
