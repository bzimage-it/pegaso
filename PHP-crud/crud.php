<?php

require_once "config.php";

$bad_req = 400;
$no_auth = 401;
$internal = 500;

function abort($msg,$code) {
    /* http_response_code ();
    http_response_code ( $code );
    http_response_code (); */
    header("Location: /crud.php",TRUE,$code);
    die ("$msg");
    echo "-------";
}

function check_and_return($what) {
    if(!isset($_GET[$what])) {
        abort("not found param: $what",$bad_req);
    }
    return $_GET[$what];
}

$cmd = check_and_return('cmd');
$pw = check_and_return('pwd');

if ( $pw != $secret) {
    abort("bad password",$no_auth);
}

if($cmd == 'create') {
    $var = check_and_return('var');
    $val = check_and_return('val');
    $filename = "$var.var";
    if(file_exists($filename)) {
        abort("var exists: $var",$bad_req);
    }
    $myfile = fopen($filename, "w") or abort("Unable to create file!",$internal);
    fwrite($myfile,$val);
    echo "CREATED $var = $val";
}

if($cmd == 'read') {
    $var = check_and_return('var');
    $filename = "$var.var";
    $myfile = fopen($filename, "r") or abort("Unable to read $var",$bad_req);
    $size=filesize($filename);
    if($size == 0) {
        echo "";
    }else{
        $val = fread($myfile,$size) or abort("cannot read on $var",$internal);
        echo "$val";
    }
}

if($cmd == 'update') {
    $var = check_and_return('var');
    $filename = "$var.var";
    $val = check_and_return('val');
    if(!file_exists($filename)) {
        abort("var do not exists: $var",$bad_req);
    }
    $myfile = fopen($filename, "w") or abort("Unable to write $var",$bad_req);
    fwrite($myfile,$val) or abort("cannot write on $var",$internal);
    echo "UPDATED $var = $val";
}

if($cmd == 'delete') {
    $var = check_and_return('var');
    $filename = "$var.var";
    if(!file_exists($filename)) {
        abort("var do not exists: $var",$bad_req);
    }else{
        unlink($filename) or abort ("cannot delete $var",$internal);
    }
    echo "DELETED $var";
}

if($cmd == 'list') {
    foreach (glob("*.var") as $filename) {
        echo basename($filename,".var")."<br>";
    }
}

http_response_code (200);
?>
