
UNAME="$1"

if [ -z "$UNAME" ]; then
    pkill -f 'firefox|chrome'
else
    pkill -u "$UNAME" -f 'firefox|chrome'
fi 
