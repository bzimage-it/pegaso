
use Math::BaseCalc;
use Devel::Size qw(size total_size);

# Come le targhe auto italiane:
# https://it.wikipedia.org/wiki/Targhe_automobilistiche_italiane#1999-oggi
#  vengono utilizzate in totale 22 lettere (quelle dell'alfabeto inglese ad esclusione di I, O, Q e U)
my $LETTERS = [
    'A','B','C','D','E','F','G','H','J','K','L',
    'M','N','P','R','S','T','V','W','X','Y','Z'
    ];
my $letters = new Math::BaseCalc(digits => $LETTERS );

my $nletters = scalar(@$LETTERS) ** 2;
my $MAX      = (scalar(@$LETTERS) ** 4) * 1000;

sub int2code {
    my $int = shift;
    my $left = $int;
    my $mod;
    if($int < $MAX) {
	
	# less significant part:
	$mod=$left % $nletters;
	my $p1 = $letters->to_base($mod);
	$p1="A".$p1 if(length($p1) == 1);	
	$left = $left / $nletters;
	
	$mod = $left % 1000;
	my $p2 = sprintf("%03d",$mod);
	$left = $left / 1000;
	
    	$mod  = $left % $nletters;
	my $p3 = $letters->to_base($mod);
	$p3="A".$p3 if(length($p3) == 1);
	return "${p3}-${p2}-${p1}";
    }else{
	warn "value $int out of bound";
    }
}


# snippet from:
# http://preshing.com/20121224/how-to-generate-a-sequence-of-unique-random-integers/
# C++ code:
# unsigned int permuteQPR(unsigned int x)
# {
#     static const unsigned int prime = 4294967291;
#     if (x >= prime)
#         return x;  // The 5 integers out of range are mapped to themselves.
#     unsigned int residue = ((unsigned long long) x * x) % prime;
#     return (x <= prime / 2) ? residue : prime - residue;
# }

sub permute
{
#    according to: http://www.cplusplus.com/forum/beginner/10076/
#    The largest prime number before $MAX=234256000 is 234255979
    my $x = shift;
    my $prime = 234255979;
    if ($x >= $prime) {
	# The 4 integers out of range are mapped to themselves.
	return $x;
    }
    my $residue = ($x ** 2) % $prime;
    return ($x <= ($prime / 2)) ? $residue : ($prime-$residue);
}


print STDERR "nletters=$nletters\nMAX= $MAX\n";

# generation & testing...

# create test hash:
# my %test = ();

for($_=0;$_<=$MAX+10000; $_ += 1) {
    #    my $coded = $letters->to_base($_);
    my $p1=permute($_);
    my $p2=permute($p1);
    my $i2c =int2code($p2);
    
    # add generated code to hash:
#    $test{$i2c}++;
#    die "error: code ${i2c} generated more times!" if($test{$i2c} > 1);

    if($_ % 100000 == 0) {
	print STDERR sprintf("%10d | %10d | %10d | %10d | %9s\n",
			     $_,$MAX-$_,$p1,$p2,$i2c);
    }
    print "$p2\n";
#    if($_ % 100000 == 0) {
#	my $total_size = int(total_size(\%test) / 1024);
#	print STDERR "$_ / total size: $total_size\n";
#    }
}

print STDERR sprintf("%10d | %9s\n",$_,int2code($MAX-1));


