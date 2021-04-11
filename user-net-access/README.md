# Project Title

A simple linux service 'daemon' script to enable/disable internet
access to some linux user by using remote variable setting.

Can be used as simple parental control.

## Description

Script

## Getting Started

### Requirements

### Installing


```
# cd /your-pegaso-root-dir/user-net-access
```

create your own configuration file:
```
# cp user-net-access.example.conf user-net-access.conf
```
and modify it accordingly to your favourite settings.

copy the user-net-access.service file to your systemd directory, eg:

```
sudo cp user-net-access.service /etc/systemd/system/
```

modify the copied file and set the correct path to your script, check and
update the line:
```
ExecStart=bash /my-pegaso-root-dir/user-net-access/user-net-access.sh
```

### Executing program

if run with no parameters, script run in 'daemon' mode, forever.

however for testing / debugging purporse script can be lauched
with two arguments:
* enable/disable string
* an existing username to act to.

e.g:
```
# sudo bash user-net-access.sh enable joe
```
## Version History

