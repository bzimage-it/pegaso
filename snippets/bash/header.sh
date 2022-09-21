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

echo "$PEGASO_ROOT"
echo "$PEGASO_PARENT_ROOT"


# param2env translation in case of env-oriented command line:

# env "$PEGASO_SCRIPT_FILE"
declare -A PEGASO_VALID_ENV_PARAMS=( [tic]=string [tac]=int [afile]=file [adir]=dir )

PEGASO_env_param_errors=0
for PP in "$@"; do
    var="${PP%=*}"
    value="${PP#*=}"
    # echo "VAR=$var VALUE=$value"
    if [[ -v "PEGASO_VALID_ENV_PARAMS[${var}]" ]]; then
	case "${PEGASO_VALID_ENV_PARAMS[${var}]}" in
	    string)
	    # no checks, any value is valid
	    ;;
	    int)
		if [[ ! "$value" == ?(-)+([0-9]) ]] ; then
		    echo "$var has invalid value $value shall be integer" >&2 
		    let PEGASO_env_param_errors+=1		    
		fi		
		;;
	    file)
		if [ ! -f "$value" ]; then
		    echo "$var hold unexisting filename: $value" >&2 
		    let PEGASO_env_param_errors+=1	    
		fi
		;;
	    dir)
		if [ ! -d "$value" ]; then
		    echo "$var hold unexisting dirname: $value" >&2 
		    let PEGASO_env_param_errors+=1	    
		fi
		;;
	    *)
		echo "invalid type for ${PEGASO_VALID_ENV_PARAMS[${var}]} (script internal error)" >&2 
		let PEGASO_env_param_errors+=1	    
		;;
	esac
	eval "$PP"
	# eval echo "PARAM SET: $var=\$$var"
    else
	echo "param $var unknown" >&2 
	let PEGASO_env_param_errors+=1
    fi
done

test $PEGASO_env_param_errors -gt 0 && exit 1


