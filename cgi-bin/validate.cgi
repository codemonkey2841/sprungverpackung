#!/usr/bin/perl -t

########
#
# Filename:        validate.cgi
# Project:         Sprungverpackung
# Number of Files: 12
# Language:        Perl/CGI
# Platform:        Linux
# Summary:         Validates the user and creates a session
#
########

# Extract the directory where the script lives
$0 =~ /^(.*)validate.cgi$/;
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

# Session stuff
my $cgi = new CGI;
my $session = new CGI::Session("driver:File", undef, {Directory=>"/tmp"});
my $sid = $session->id();
$cookie = $cgi->cookie(SID => $sid);

if (!$cgi->param('uname')) {
   # User isn't logged in
   print $cgi->redirect( -cookie=>$cookie,
                         -status=>'302 Moved', 
                         -uri=>'/sprung/index.html');
   exit;
}

# Create encrypted tunnel to server
my $pid = setup_encrypted_tunnel($user,
                                 $host,
                                 $local_port,
                                 $remote_port,
                                 $ifile);
my $socket = setup_connection($host, $remote_port);
setSocket($socket);
getLine();
# Clean input
my $user = scrubString($cgi->param('uname'), '[\w\d]');
my $passwd = scrubString($cgi->param('passwd'),
                         '[\w\d\+\_\-\=\,\.\!\@\#\%\^\&\*]');

# Authenticate the user
if (connectLink($user, $passwd)) {
   # User is authenticated
   $session->param('user', $user);
   $session->param('passwd', $passwd);
   print $cgi->redirect( -cookie=>$cookie, 
                         -status=>'302 Moved', 
                         -uri=>'/sprung/list.html');
} else {
   # User is not authenticated
   print "Content-type:text/html\n\n";
   print "The username or password supplied does not match our records."
   print '<br />\n<a href="/sprung/">Back to Login Page</a>' . "\n";
}

# Kill the tunnel process
`kill $pid`;
