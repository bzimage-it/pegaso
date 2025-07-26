
VER=5.65.19
ZFILE=codemirror.zip

IPATH=codemirror-$VER
test ! -f $ZFILE && wget https://codemirror.net/5/$ZFILE

DIRS="lib theme mode"
rm -rf $DIRS
unzip $ZFILE
for D in $DIRS; do
	mv -v $IPATH/$D/ .
done
rm -rf $IPATH
pwgen 15 1 > pwd.secret && echo "a new secret file have been generated"
