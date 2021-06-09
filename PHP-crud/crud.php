<?php

require "config.php";

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

function return_if_def($what,$default) {
    if(!isset($_GET[$what])) {
        return $default;
    }
    return $_GET[$what];
}


function read_filename($filename) {
    $myfile = fopen($filename, "r") or abort("Unable to read $var",$bad_req);
    $size=filesize($filename);
    if($size == 0) {
        return "";
    }else{
        $val = fread($myfile,$size) or abort("cannot read on $var",$internal);
        return $val;
    }
}

$cmd = check_and_return('cmd');
$pw = check_and_return('pwd');
$verbose = return_if_def('verbose',"1");

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
    if($verbose) {
        echo "CREATED $var = $val";
    }else{
        echo "$val";
    }
}

if($cmd == 'read') {
    $var = check_and_return('var');
    $filename = "$var.var";
    $val = read_filename($filename);
    echo "$val";
}

if($cmd == 'update') {
    /* note that an "update & read" effect in one shot can be get setting verbose=0 */
    $var = check_and_return('var');
    $filename = "$var.var";
    if(!file_exists($filename)) {
        abort("var do not exists: $var",$bad_req);
    }
    /* only one of 'val' , 'inc' , 'dec' can be defined: */
    $val = return_if_def('val',"");
    $inc = return_if_def('inc',"");
    $dec = return_if_def('dec',"");
    $ndef = ( (int) (bool) $val ) + ( (int) (bool) $inc ) + ( (int) (bool) $dec ) ;
    if ($ndef==0) {
        abort("no option defined between: val, inc, dec",$bad_req);
    }elseif($ndef>1) {
        abort("incompatible option defined, only one between: val, inc, dec; $ndef defined in total",$bad_req);
    }
    if($inc or $dec) {
        $curval = read_filename($filename);
        if($inc) {
            $val = $curval + $inc;
        }
        if($dec) {
            $val = $curval - $dec;
        }
    }
    $myfile = fopen($filename, "w") or abort("Unable to write $var",$bad_req);
    fwrite($myfile,$val) or abort("cannot write on $var",$internal);
    if($verbose) {
        echo "UPDATED $var = $val";
    }else{
        echo "$val";
    }
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