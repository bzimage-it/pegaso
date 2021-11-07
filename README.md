# pegaso

Pegaso is my own code snippet and library for linux.
Different languages like bash, perl, etc... for doing all day work.

# installation

get pegaso into your favourite dir, e.g. $HOME/opt:

`cd && mkdir opt && cd opt`

`git clone https://github.com/bzimage-it/pegaso.git`

then execute, one time only:

`bash pegaso/post-install.sh`

then, tell bash to use pegaso, edit your $HOME/.bashrc and add:

`export PATH="$PATH:$HOME/opt/pegaso/bin"`

`export PEGASO_ROOT="$HOME/opt/pegaso"`

at the end you may also want to add:

`source $PEGASO_ROOT/lib/bash/bashrc.lib.sh`

# usage

pegaso provides different commands:

`pegaso-*`

# utils and utils2

`$PEGASO_ROOT/lib/bash/utils.lib.sh`
and
`$PEGASO_ROOT/lib/bash/utils2.lib.sh`

provides powerfull functions to your bash. 

`utils.sh` is considered legasy.
they can be "source"-ed directly or copied as your own script:
 `cp $PEGASO_ROOT/lib/bash/utils2.lib.sh /dir/myownscript.sh`

`utils2` provides:
* log function support log level, colors, file descriptiors.
* temporary file and automatic cleanup
* debuggin with stack trace
see source code for more details.
you can also execute a demo directly executing:

`bash $PEGASO_ROOT/lib/bash/utils2.lib.sh`

# Other compoments and tools

* ```PHP-crud``` is a simple PHP script to execute C-R-U-D operations on remote variable that can be used for remote configuration and settings.
* ```user-net-access``` is a simple daemon to enable or disable internet access for some specific user list on a linux host. Can be used for simple parental control. Require ```PHP-crud``` to be available somewhere.







