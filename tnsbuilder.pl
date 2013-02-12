#!perl
# TnsBuilder
# Created by Seth Miller 2013/02
# Version 1.1

# Use the --man switch for details on what this script does and how to use it.
# The script is also heavily commented.


use XML::Twig;
use Getopt::Long;
use Pod::Usage;


my $namefield = "NAME";
my $idprefix = '@ID=';
my $servicenameid = "1";
my $help = 0;
my $man = 0;
my $printtoscreen = 0;
my $xmlin;
my $namefield;
my $instanceid;
my $twigfilter;

GetOptions ( help => \$help,
             man => \$man,
             print => \$printtoscreen,
             "xmlin=s" => \$xmlin,
             "namefield:s" => \$namefield,
             "namesuffix:s" => \$namesuffix,
             "instanceid:s" => \$instanceid,
             "servicenameid:s" => \$servicenameid,
             "filter:s" => \$twigfilter
) || pod2usage(2);

pod2usage(1) if ($help);
pod2usage(-verbose => 2) if ($man);

# Regex filter for all twigs starting at the title element (TNS)
# For example: include DBID's that start with 17 and exclude all
#   names that start with EID
#   "[@DBID =~ /^17/ and @NAME !~ /^EID/]"
$twigfilter = 'TNS' . $twigfilter;
#print "$twigfilter\n";

# Print the output to a file if a filename is defined as the last argument
my $outfile = $ARGV[0];
# Put an underscore in front of the name suffix if it is defined
$namesuffix = "_$namesuffix" if $namesuffix;

sub rootone {
	my ($twig, $tns) = @_;

	# A new twig is defined that will hold the final product after all of the following manipulations
	$final = new XML::Twig::Elt('DESCRIPTION');

	# Grab the name as defined by $namefield, otherwise assign NAME which should always exist
	if ( $tns->att(qq{$namefield}) ) {
		$name = $tns->att(qq{$namefield});
	} else {
		$name = $tns->att('NAME');
	};

#	$tns->att('DBID')->parent->print;
#	exit;

	# If there are spaces in the name, replace them with underscores
	$name =~ s/ /_/g;
	$desc = $tns->first_child('DESCRIPTION')->cut;
	$addr = $desc->first_child('ADDRESS_LIST')->cut;
	$conn = $desc->first_child('CONNECT_DATA')->cut;
	$serv = $conn->first_child('SERVICE_NAMES')->cut;

	# Check if INSTANCES exists
	if ( $conn->first_child('INSTANCES') ) {
		$inst = $conn->first_child('INSTANCES')->cut;
			# If $instanceid is defined and the element exists, assign and paste to the end product
			if ( $instanceid && $inst->first_child(qq{INSTANCE [$idprefix$instanceid]}) ) {
				$sinst = $inst->first_child(qq{INSTANCE [$idprefix$instanceid]})->del_att('ID')->cut;
				$sinst->paste( last_child => $conn );
			}
	}

	# If the $servicenameid element exists, assign otherwise assign ID 1 which should always exist
	if ( $serv->first_child(qq{SERVICE_NAME [$idprefix$servicenameid]}) ) {
		$sserv = $serv->first_child(qq{SERVICE_NAME [$idprefix$servicenameid]})->del_att('ID')->cut;
	} else {
		$sserv = $serv->first_child('SERVICE_NAME [@ID=1]')->del_att('ID')->cut;
	}

	# Paste the service name to the end product
	$sserv->paste( last_child => $conn );
	# The name of the tns entry is a combination of $name and $namesuffix
	$title = "\n\n$name$namesuffix =\n";
	$addr->paste( $final );
	$conn->paste( last_child => $final->children ); 
	# Combine the $title and the $final twig
	$sfinal = $title . $final->sprint;
	
	# Replace all opening tags with a "(" with two spaces in front of it for indentation
	$sfinal =~ s!<(\w+)>!  (\1 = !g;

	# Replace all closing tags that are on their own line with a ")" and two spaces in front of it for indentation 
	$sfinal =~ s!(?<=\n)(\s*)</\w+>!\1  )!g;

	# Replace all closing tags that are on the same line with their text with a ")" and no leading spaces
	$sfinal =~ s!</\w+>!)!g;

	# Print to screen if $printtoscreen is defined
	print $sfinal if $printtoscreen;
	# Print to the output file if it is defined
	print MYFILE $sfinal if $outfile;
}


my $twig = new XML::Twig( twig_handlers => { qq{$twigfilter} => \&rootone },
                          pretty_print => 'indented');

# Open the file for output if it is defined
open (MYFILE, ">", $outfile) if $outfile;

$twig->parsefile($xmlin);

# Close the file for output if it is defined
close (MYFILE) if $outfile;

__END__

=head1 NAME

TnsBuilder

=head1 SYNOPSIS

tnsbuilder.pl [options] [file]

=head1 OPTIONS

=over 8

=item B<--help>

Print brief help message

=item B<--man>

Prints the full manual

=item B<--print>

Optional. Print the output to the screen.

=item B<--xmlin FILE>

Required. Input XML file for parsing.

=item B<--namefield NAME|DBID>

Optional. Choose what will make up the title of the entry,
the NAME or DBID. NAME is the default.

=item B<--namesuffix SUFFIX> 

Optional. The SUFFIX will be added to the title of the entry
after an underscore (i.e. NAME_SUFFIX). Null is the default.

=item B<--instanceid ID>

Optional. The id number of the instance to include in the connection
(i.e. 1). Null is the default.

=item B<--servicenameid ID>

Optional. The id number of the service name to include in the
connection (i.e. 1). 1 is the default.

=item B<--filter FILTER>

Optional. Used to include and/or exclude entries from the output. The
filter is regex style as applied to the twig_handlers clause of XML::Twig.
See the XML::Twig page on CPAN for further information.

For example:
This will include DBID's that start with 17 and exclude all NAME's that
start with EID

"[@DBID =~ /^17/ and @NAME !~ /^EID/]"

=back

=head1 DESCRIPTION

B<This program> will read an XML file with a tnsnames connection string format
and parse it according to the options provided to the script. The output will be
a tnsnames.ora type file with Oracle readable connection strings.

=cut
