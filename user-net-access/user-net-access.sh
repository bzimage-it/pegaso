#!/bin/bash

PEGASO_START_SCRIPT_PWD=$(pwd)

# this is a code snipped:
# from http://stackoverflow.com/questions/59895/can-a-bash-script-tell-what-directory-its-stored-in
# to understand what directory it's stored in bash script itself

PEGASO_SOURCE="${BASH_SOURCE[0]}"
while [ -h "$PEGASO_SOURCE" ]; do # resolve $SOURCE until the file is no longer a symlink
  PEGASO_DIR="$( cd -P "$( dirname "$PEGASO_SOURCE" )" && pwd )"
  PEGASO_SOURCE="$(readlink "$PEGASO_SOURCE")"
  [[ $PEGASO_SOURCE != /* ]] && PEGASO_SOURCE="$PEGASO_DIR/$PEGASO_SOURCE" # if $SOURCE was a relative symlink, we need to resolve it relative to the path where the symlink file was located
done
PEGASO_SCRIPT_DIR="$( cd -P "$( dirname "$PEGASO_SOURCE" )" && pwd )"
PEGASO_SCRIPT_FILE=$(basename "$PEGASO_SOURCE")
# end of snipped

cd "$PEGASO_SCRIPT_DIR"
cd .. || exit 1
export PEGASO_ROOT="$(pwd)"

PEGASO_PARENT_ROOT="$(dirname "$PEGASO_ROOT")"

# echo "$PEGASO_ROOT"
# echo "$PEGASO_PARENT_ROOT"

foutput=/tmp/netaccess-out.tmp
fcode=/tmp/netaccess-code.tmp


CMD="$1"
function log() {
    echo $(date --iso-8601=seconds)" $*"
}

function abort() {
    log "abort: $1"
    exit 1
}

function load_conf() {
    local conf="$(dirname "$1")/""$(basename "$1" .sh)"
    conf+=".conf"
    log "loading $conf"
    if [ -f "$conf" ]; then
	source "$conf" || log "not found: $conf"
	log "conf successfully loaded"
	# env:
	test -z "$UNA_SLEEP" && UNA_SLEEP=$((5*60))
	log "using UNA_SLEEP=$UNA_SLEEP"
	test -z "$UNA_USERS" && UNA_USERS=$USER
	log "using UNA_USERS=$UNA_USERS"
	test -z "$UNA_IF" && abort "undefined env UNA_IF"
	log "using UNA_IF=$UNA_IF"

	test -z "$UNA_CRUD_PWD"  && abort "undefined env UNA_CRUD_PWD"
	test -z "$UNA_CRUD_URL"  && abort "undefined env UNA_CRUD_URL"
	return 0
    fi
    return 1
}


log "STARTING $0"

load_conf "${PEGASO_SCRIPT_DIR}/${PEGASO_SCRIPT_FILE}" ||    
    load_conf "/etc/${PEGASO_SCRIPT_FILE}" ||
    load_conf "/usr/local/etc/${PEGASO_SCRIPT_FILE}" || abort "cannot load any configuration file"

function filter() {
    local USERNAME="$1"
    iptables -L OUTPUT --line-numbers | grep DROP | grep "owner UID match $USERNAME" | cut -f 1 -d " " | head -n 1
    return $?
}

function action() {
    local CMD="$1"
    local USERNAME="$2"
    local UNA_UID="$(id -u "$USERNAME")"
    log "action: $CMD on user $USERNAME (uid=$UNA_UID) ..."
    case "$CMD" in
	disable)
	    ID=$(filter)
	    if [ -n "$ID" ]; then
		log "already disabled, skipped"
	    else
		iptables -A OUTPUT -o "$UNA_IF" -m owner --uid-owner "$UNA_UID" -j DROP
	    fi
	    ;;
	enable)
	    # drop all rules:
	    ID=1
	    while [ -n "$ID" ]; do
		ID=$(filter $USERNAME)
		# log "deleting rule '$ID'"
		if [ -n "$ID" ]; then
		    iptables -D OUTPUT "$ID"
		    log "removed rule for user $USERNAME line $ID"
		fi
	    done
	    ;;
	show)
	    iptables -L OUTPUT
	    ;;
	*)
	    abort "$CMD unknown"
	    ;;
    esac
    return 0
}

if [ -n "$2" ]; then
    # used for testing:
    action "$1" "$2"
    exit 0
fi

if [ $UID != 0 ]; then
    log "cannot run: shall be root"
    exit 1
fi

rm -f "$foutput" "$fcode"

while true; do    
    for UNA_USER in $UNA_USERS; do
	var=$(eval "$UNA_CRUD_VAR_TEMPLATE")
	url="${UNA_CRUD_URL}?cmd=read&var=${var}&pwd=${UNA_CRUD_PWD}"
	log GET: $url	
	curl --silent "$url" -o $foutput -w "%{http_code}" > $fcode
	CODE=$(cat $fcode)
	OUT=$(cat $foutput)
	log RESPONSE: [$CODE] $OUT
	case "$CODE" in
	    200)
		case "${OUT^^}" in
		    "DISABLED"|"DISABLE"|"N"|"NO")
			action disable $UNA_USER
			;;
		    "ENABLED"|"ENABLE"|"Y"|"YES")
			action enable $UNA_USER
			;;
		    *)
			log "username=$UNA_USER error value: $OUT"
			;;
		esac
		;;
	    *)
		log "username=$UNA_USER http response: $CODE"
		;;
	esac
    done
    log "going sleep for $UNA_SLEEP secs: zzzzz..."
    sleep $UNA_SLEEP
done
