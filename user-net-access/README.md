# user-net-access

A simple linux service 'daemon' script to enable/disable internet
access to some linux user by using remote variable setting.

Can be used as simple parental control.

### Description

script need to be run using daemon service, for example ```systemd``` and
```systemctl```

### Requirements

* a CRUD-php (see it) service (find it on PEGASO) shall be
  running on some remote url for example:
  ```https://example.com/crud/crud.php```

* program have been tested on Ubuntu Linux 20.04.1 LTS (Focal Fossa)
  although any other recent standard linux version shall works too.

### Installing

```
# cd /your-pegaso-root-dir/user-net-access
```

create your own configuration file:
```
# cp user-net-access.example.conf user-net-access.conf
```
and modify it accordingly to your favourite settings.

NOTE: configuration file can be locaced also in other places:
      ```/etc``` or ```/usr/local/etc```

copy the user-net-access.service file to your systemd directory, eg:

```
sudo cp user-net-access.service /etc/systemd/system/
```
make executable the script:

```sudo chmod +x /my-pegaso-root-dir/user-net-access/user-net-access.sh```

modify the copied file and set the correct path to your script, check and
update the line:

```
ExecStart=/my-pegaso-root-dir/user-net-access/user-net-access.sh
```
then enabling and activate with systemd:

```
# sudo systemctl enable user-net-access
# sudo systemctl status user-net-access
```

then start the service:

```# sudo systemctl start user-net-access```

you can check that all is running:

```# sudo systemctl status user-net-access```

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

