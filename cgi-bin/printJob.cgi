#!/usr/bin/perl -t

########
#
# Filename:        printJob.cgi
# Project:         Sprungverpackung
# Number of Files: 12
# Language:        Perl/CGI
# Platform:        Linux
# Summary:         Releases the specified job(s) to the appropriate printer.
#
########

# Extract the directory where the script lives
$0 =~ /^(.*)printJob.cgi$/;
my $dir = $1;

use lib $dir;
use CGI;
use CGI::Session;
use Config::Simple;
use WECNnet;
use Release;

# Gather variables from config file
Config::Simple->import_from($dir . 'sprung.ini', \%config);
my $host = $config{'default.host'};
my $local_port = $config{'default.local'};
my $remote_port = $config{'default.remote'};
my $user = $config{'default.user'};
my $idfile = $config{'default.idfile'};
# Needs to be in the form 'ip address'=>'queue', ...
my $prints = $config{'default.printers'};

eval{ my %printers = ( $prints ) };

my $cgi = new CGI;
my $sid = $cgi->cookie("SID");
my $session = new CGI::Session(undef, $sid, {Directory=>'/tmp'});

# establish tunnel
my $pid = setup_encrypted_tunnel($user, $host, $local_port,
$remote_port, $ifile);
my $socket = setup_connection($host, $remote_port);
setSocket($socket);
getLine();

print "Content-type:text/html\n\n";

# authenticate the user
if (!connectLink($session->param('user'), $session->param('passwd'))) {
  print -1;
  exit;
}

# gather all checked items from previous form
@param = $cgi->param();
if ($param[-1] =~ /\D/) {$printer = $cgi->param(pop(@param));}

# retrieve printer to print to
$ip = $ENV{'REMOTE_ADDR'};
if ($printer eq "") {$printer = $printers{$ip};}

# submit request to release jobs to the specified printer
if ($printer eq "") {
  print -2;
  exit;
}
$a = 0;
foreach $val (@param) {
  $new = scrubString($val, '[\d]');
  if ($new ne "") {
    $b = printJob($new, $printer);
    if ($b =~ /BAD/) {$a = 1;};
  }
}
if ($a) {
  print 0;
} else {
  print 1;
}

`kill $pid`;
