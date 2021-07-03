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


tdir=/tmp/user-net-access
wakeupdir=$tdir/wakeup
foutput=$tdir/out.tmp
fcode=$tdir/code.tmp
LOCKFILE=/var/run/user-net-access.pid

P_COMMAND="$1"
P_USER="$2"

function log() {
    echo "$$ "$(date --iso-8601=seconds)" $*"
}

function cleanup() {
    log "EXIT CLEANUP PID $$"
    rm -rfv $LOCKFILE $tdir 
}

trap 'log "Caught SIGUSR1 (debugging)"' SIGUSR1

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
	test -z "$UNA_SLEEP_M" && UNA_SLEEP_M=5
	UNA_SLEEP=$(($UNA_SLEEP_M*60))
	log "using UNA_SLEEP_M=$UNA_SLEEP_M ($UNA_SLEEP secs)"
	test -z "$UNA_USERS" && UNA_USERS=$USER
	log "using UNA_USERS=$UNA_USERS"
	test -z "$UNA_IF" && abort "undefined env UNA_IF"
	log "using UNA_IF=$UNA_IF"

	test -z "$UNA_CRUD_PWD"  && abort "undefined env UNA_CRUD_PWD"
	test -z "$UNA_CRUD_URL"  && abort "undefined env UNA_CRUD_URL"
	test -z "$UNA_IPTABLES_USER_CHAIN_PREFIX" && abort "undefined env UNA_IPTABLES_USER_CHAIN_PREFIX"
	test -z "$UNA_IPTABLES_TRAFFIC_THRESHOLD_PER_MINUTE" && abort "undefined env UNA_IPTABLES_TRAFFIC_THRESHOLD_PER_MINUTE" 
	return 0
    fi
    return 1
}


log "STARTING $0 [ PID= $$ ]"

load_conf "${PEGASO_SCRIPT_DIR}/${PEGASO_SCRIPT_FILE}" ||    
    load_conf "/etc/${PEGASO_SCRIPT_FILE}" ||
    load_conf "/usr/local/etc/${PEGASO_SCRIPT_FILE}" || abort "cannot load any configuration file"

function filter() {
    local USERNAME="$1"
    iptables -L OUTPUT --line-numbers | grep DROP | grep "owner UID match $USERNAME" | cut -f 1 -d " " | head -n 1
    return $?
}

function read_traffic() {
    local USERNAME="$1"
    local traffic_chain="${UNA_IPTABLES_USER_CHAIN_PREFIX}${USERNAME}"
    iptables -L OUTPUT -n -v -x | grep $traffic_chain | awk -- '{print $2}'
}


function action() {
    local CMD="$1"
    local USERNAME="$2"
    local UNA_UID="$(id -u "$USERNAME")"
    local traffic_chain="${UNA_IPTABLES_USER_CHAIN_PREFIX}${USERNAME}"
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
	create-user-chain)
	    iptables -N $traffic_chain
	    ;;
	drop-traffic-monitor)
	    ret=0
	    # continue to drop rule until found them:
	    while [ $ret == 0 ]; do
		iptables -D OUTPUT -m owner --uid-owner $UNA_UID -j $traffic_chain 2> /dev/null
		ret=$?
	    done
	    ;;
	start-traffic-monitor|restart-traffic-monitor)
	    action drop-traffic-monitor $USERNAME
	    action install-traffic-monitor $USERNAME
	    ;;
	install-traffic-monitor)
	    iptables -A OUTPUT -m owner --uid-owner $UNA_UID -j $traffic_chain
	    ;;
	show)
	    iptables -L OUTPUT -n -v	    
	    ;;
	wakeup)
	    if [ -f ${LOCKFILE} ]; then
		THEPID=`cat ${LOCKFILE}`
		# kill -0 $THEPID
		log "wake up PID: $THEPID"
	    else
		log "WARNING: no daemon seems to be running"
	    fi
	    wf=$wakeupdir/"$USERNAME.$USER.$$.$RANDOM"
	    echo > $wf
	    rm -f $wf
	    log "written and removed: $wf"	    
	    ;;
	*)
	    abort "$CMD unknown"
	    ;;
    esac
    return 0
}


for C in curl inotifywait; do
    which $C || abort "command needed: $C"
    log "FOUND: $C"
done

if [ -n "$P_USER" ]; then
    # used for testing:
    action "$P_COMMAND" "$P_USER"
    exit 0
fi

if [ -n "$P_COMMAND" ] ; then
    abort "given one param only"
fi

# goes in Daemon mode:
# only root can run:
if [ $UID != 0 ]; then
    abort "cannot run: shall be root"
fi
# check lockfile:
if [ -f ${LOCKFILE} ]; then
    THEPID=`cat ${LOCKFILE}`
    log "found PID $THEPID"
    kill -0 $THEPID && abort "already running as PID="$(cat ${LOCKFILE})
fi
# install cleanup trap and create lockfile:
trap 'cleanup;exit 2;' INT TERM EXIT
echo $$ > ${LOCKFILE}
# THEPID=`cat ${LOCKFILE}`
# log "found --- PID $THEPID"
rm -rf $tdir || abort "cannot remove $tdir"
mkdir -m 767 -p $tdir || abort "cannot create $tdir"
mkdir -m 767 -p $wakeupdir || abort "cannot create $wakeupdir"

for UNA_USER in $UNA_USERS; do
    action create-user-chain $UNA_USER
done

while true; do    
    for UNA_USER in $UNA_USERS; do
	
	var=$(eval "$UNA_CRUD_VAR_TEMPLATE")
	url="${UNA_CRUD_URL}?cmd=read&var=${var}&pwd=${UNA_CRUD_PWD}"
	log GET: $url	
	curl --silent "$url" -o $foutput -w "%{http_code}" > $fcode
	CODE=$(cat $fcode)
	OUT=$(cat $foutput)
	log "read | RESPONSE: " [$CODE] $OUT
	case "$CODE" in
	    200)
		OUT="${OUT^^}"
		case "${OUT}" in
		    "DISABLED"|"DISABLE"|"N"|"NO")
			action disable $UNA_USER
			;;
		    "ENABLED"|"ENABLE"|"Y"|"YES")
			action enable $UNA_USER
			;;
		    *)
			if [[ $OUT =~ ^[+-]?[0-9]+$ ]] ; then
			    if [ "$OUT" -le 0 ]; then
				action disable $UNA_USER
			    else
				action enable $UNA_USER
				# if is a number, go in traffic monitoring and decrementing
				# time-slot
				traffic="$(read_traffic $UNA_USER)"
				traffic_per_minute=0
				test -n "$traffic" && let traffic_per_minute="$traffic / $UNA_SLEEP_M"
				log "traffic=$traffic traffic_per_minute=$traffic_per_minute"
				if [ -n "$traffic" -a "$traffic_per_minute" -gt "$UNA_IPTABLES_TRAFFIC_THRESHOLD_PER_MINUTE" ]; then
				    log "traffic is over threadshold $UNA_IPTABLES_TRAFFIC_THRESHOLD_PER_MINUTE"		    
				    url="${UNA_CRUD_URL}?cmd=update&var=${var}&verbose=0&dec=${UNA_SLEEP_M}&pwd=${UNA_CRUD_PWD}"
				    log GET: $url
				    curl --silent "$url" -o $foutput -w "%{http_code}" > $fcode
				    CODE2=$(cat $fcode)
				    OUT2=$(cat $foutput)
				    log "update | RESPONSE: " [$CODE2] $OUT2
				else
				    log "traffic is under threadshold $UNA_IPTABLES_TRAFFIC_THRESHOLD_PER_MINUTE"
				fi
				action restart-traffic-monitor $UNA_USER
			    fi
			else
			    log "not a valid value for var: ${var} = $OUT"
			fi
			;;
		    *)
			log "username=$UNA_USER error value: $OUT"
			;;
		esac
		;;
	    *)
		log "read | username=$UNA_USER http response: $CODE"
		;;
	esac
    done
    log "going sleep for $UNA_SLEEP secs: zzzzz..."
    # this "& + wait" is for allow debugging without spent time, use kill -SIGUSR1 to break sleep or use "wakeup" param
    # sleep $UNA_SLEEP &
    inotifywait -t $UNA_SLEEP -e create --quiet $wakeupdir
    # wait $!
done
