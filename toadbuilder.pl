use XML::Twig;
use Data::Dumper;
use Getopt::Long;

GetOptions ( "xmlin=s" => \$xmlin,
             print => \$printtoscreen,
             "users:s" => \@users );

@users = split(/,/,join(',',@users));
my $outfile = $ARGV[0];

my $tnsname = "DBID";
my $readablename = "NAME";
my $asmatt = "ASM";
my $sysuser = "SYS";

# Exclude asm connections except for sys
my $xasmsys = "T";

my $titlecount = 1;


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


# Loop through all of the usernames
# Grab the connectas if it is attached
foreach my $username (@users) {
	( my $username, my $connectas ) = split(/:/,$username);

$connectas = "NORMAL" if $connectas eq '';

# If the entry is ASM and the user is not SYS and xasmsys is set to T, skip
if ( $tns->att(qq{$asmatt}) eq "TRUE" && $username ne $sysuser && $xasmsys eq "T" ) {
	return;
}

my $toaduser = "EXTERNAL";
my $toadtitle = "LOGIN" . $titlecount++;
my $toadserver = $dbid . "_" . $username;
my $toadautoconnect = "0";
my $toadoraclehome;
my $toadsavepassword = "0";
my $toadfavorite = "0";
my $toadsessionreadonly = "0";
my $toadalias = $readname . "_" . $username;
my $toadhost;
my $toadinstancename;
my $toadservicename;
my $toadsid;
my $toadport;
my $toadldap;
my $toadmethod = "0";
my $toadprotocol = "TNS";
my $toadprotocolname = "TCP";
my $toadcolor;
my $toadconnectas = $connectas;
my $toadlastconnect;
my $toadrelativeposition = "1";


# Template for Toad connection script
my $toadtemp = <<END;
[$toadtitle]
User=$toaduser 
Server=$toadserver
AutoConnect=$toadautoconnect
OracleHome=$toadoraclehome
SavePassword=$toadsavepassword
Favorite=$toadfavorite
SessionReadOnly=$toadsessionreadonly
Alias=$toadalias
Host=$toadhost
InstanceName=$toadinstancename
ServiceName=$toadservicename
SID=$toadsid
Port=$toadport
LDAP=$toadldap
Method=$toadmethod
Protocol=$toadprotocol
ProtocolName=$toadprotocolname
Color=$toadcolor
ConnectAs=$toadconnectas
LastConnect=$toadlastconnect
RelativePosition=$toadrelativeposition

END

print "$toadtemp" if $printtoscreen == 1;
print MYFILE $toadtemp if $outfile ne "";

}
}

my $twig = new XML::Twig( twig_roots => { 'TNS' => \&rootone },
                          pretty_print => 'indented');

open (MYFILE, ">", $outfile) if $outfile ne "";

$twig->parsefile($xmlin);

my $endtext = <<END;
[NumberCustomField]
NUMBER=0

<<Split file here. CONNECTIONS.INI above, CONNECTIONPWDS.INI below>>
END

print "$endtext\n" if $printtoscreen == 1;
print MYFILE $endtext if $outfile ne "";

close (MYFILE) if $outfile ne "";
