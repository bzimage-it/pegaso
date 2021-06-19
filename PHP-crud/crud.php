<?php

require "config.php";

$bad_req = 400;
$no_auth = 401;
$internal = 500;
$cmd_error = TRUE;
$this_script="/crud/crud.php";
define('CSSPATH', './'); //define css path
$hname = $_SERVER['host_name'];

function abort($msg,$code) {
    /* http_response_code ();
    http_response_code ( $code );
    http_response_code (); */
    global $hname;
    global $this_script;
    header("Location: $this_script",TRUE,$code);
    die ("$hname : $this_script : $msg");
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

function field($t,$k,$v) {
    echo "<input type=\"$t\" id=\"$k\" name=\"$k\" value=\"$v\">";
}

function echo_tag($name,$attr,$endtag) {
    echo "<$name";
    foreach ($attr as $k => $v ) {
        echo " $k=\"$v\"";
    }
    echo $endtag;
}


function read_filename($filename) {
    $myfile = fopen($filename, "r") or abort("Unable to read $var",$bad_req);
    $size=filesize($filename);
    if($size == 0) {
        return "";
    }else{
        # echo "BYTES($size)";
        # curious bug here: using fread do not work if string into file start with '0' then reading fails; why?
        # but file_get_contents seems to work.
        # $val = fread($myfile,$size) or abort("cannot read on $filename",$internal);
        $val = file_get_contents($filename);
        # echo "VAL($val)";
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
    $cmd_error = FALSE;
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
    $cmd_error = FALSE;
    $var = check_and_return('var');
    $filename = "$var.var";
    $val = read_filename($filename);
    echo "$val";
}

if($cmd == 'update') {
    $cmd_error = FALSE;
    /* note that an "update & read" effect in one shot can be get setting verbose=0 */
    $var = check_and_return('var');
    $filename = "$var.var";
    if(!file_exists($filename)) {
        abort("var do not exists: $var",$bad_req);
    }
    /* only one of 'val' , 'inc' , 'dec' can be defined: */
    $val = return_if_def('val',"");
    $val_special = return_if_def('val_special',"");
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
        $val = "$val";
    }
    if($val_special) {
        /* if given, take precedente over all: */
        $val = $val_special;
    }
    $myfile = fopen($filename, "w") or abort("Unable to write $var",$bad_req);
    # echo "W($val)";
    fwrite($myfile,$val) or abort("cannot write on $var",$internal);
    if($verbose) {
        echo "UPDATED $var = $val";
    }else{
        echo "$val";
    }
}

if($cmd == 'update_interactive') {
    $cmd_error = FALSE;
    /* note that an "update & read" effect in one shot can be get setting verbose=0 */
    $var = check_and_return('var');
    $filename = "$var.var";
    if(!file_exists($filename)) {
        abort("var do not exists: $var",$bad_req);
    }
    $specials = return_if_def('specials',"");
    $curval = read_filename($filename);
    
    /*
     css credits and snippet from: 
     https://stackoverflow.com/questions/10876953/how-to-make-a-radio-button-unchecked-by-clicking-it
     https://stackoverflow.com/questions/6315772/how-to-import-include-a-css-file-using-php-code-and-not-html-code/6315792 
    */
    
    $cssItem = 'crud.css'; //css item to display
    ?>    

    <html>
    <head>
    <title><?php echo $var; ?> modify</title>
    <link rel="stylesheet" href="<?php echo (CSSPATH . "$cssItem"); ?>" type="text/css">
    </head>
    <body>
    <?php

    echo "<form action=\"$this_script\" method=\"get\">";
    echo "<label for=\"val\">value for variable:<br><b>$var</b></label><br>";
    field('text','val',$curval);
    field('hidden','pwd',$pw);
    field('hidden','var',$var);
    field('hidden','cmd','update');
    if($specials) {
        echo "<p>You may also choose special values:</p>";
        
        echo_tag('input', array( 
                'type' => 'radio',
                'name' => 'val_special',
                'id' => 'uncheckAll',
                'value' => "", # this is in order to pass in the submit a val_special = '' and avoid it's effect in 'update' command when no radio buttons are checked 
                'checked' => 'checked'
             ), '/>');
        # echo "<input type=\"radio\" name=\"val_special\" id=\"uncheckAll\" checked=\"checked\" />";
        
        $a_specials = explode(",", $specials);
        # echo "<div>";
        foreach ($a_specials as &$s) {
            echo "<label>";
            echo_tag('input', array( 
                        'type' => 'radio',
                        'name' => 'val_special',
                        'id' => "v_$s",
                        # 'checked' => 'unchecked',
                        'value' => $s,
                   ), '/>');
                # <input type="radio" name="group1" id="radio2" />
            echo_tag ( 'label', array(
                   'for' => 'uncheckAll'
                ),'></label>');
            echo "$s</label><br>";
            # echo "<input type=\"radio\" id=\"v_$s\" name=\"val_special\" value=\"$s\">";
            # echo "<label for=\"v_$s\">$s</label>";
        }
        # echo "</div>";
    }
    echo "<br><input type=\"submit\" value=\"UPDATE\">";
    echo "</form>";
    echo "</body>";
    echo "</html>";
}


if($cmd == 'delete') {
    $cmd_error = FALSE;
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
    $cmd_error = FALSE;
    foreach (glob("*.var") as $filename) {
        echo basename($filename,".var")."<br>";
    }
}

if($cmd_error) {
    abort("unrecognized command: $cmd",$bad_req);
}
http_response_code (200);
?>