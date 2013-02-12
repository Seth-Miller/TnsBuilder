use XML::Twig;
use Data::Dumper;
use Getopt::Long;

GetOptions ( "xmlin=s" => \$xmlin,
             print => \$printtoscreen,
             "users:s" => \@users );

@users = split(/,/,join(',',@users));
my $outfile = $ARGV[0];


sub rootone {

my ($twig, $tns) = @_;
$final = new XML::Twig::Elt('DESCRIPTION');

if ( $tns->att(qq{$tnsname}) ) {
	$dbid = $tns->att(qq{$tnsname});
} else {
	$dbid = $tns->att('NAME');
}

if ( $tns->att(qq{$readablename}) ) {
	$readname = $tns->att(qq{$readablename});
} else {
	$readname = $tns->att('NAME');
}

}

my $twig = new XML::Twig( twig_roots => { 'ENTRIES' => \&rootone },
                          pretty_print => 'indented');

open (MYFILE, ">", $outfile) if $outfile ne "";

$twig->parsefile($xmlin);
$twig->print if $printtoscreen == 1;
$twig->print_to_file($outfile) if $outfile ne "";

