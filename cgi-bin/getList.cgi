#!/usr/bin/perl -t

########
#
# Filename:        getList.cgi 
# Project:         Sprungverpackung
# Number of Files: 12
# Language:        Perl/CGI
# Platform:        N/A
# Summary:         Retrieves a list of jobs from the print queue for the user.
#
########

use lib "./";
use CGI;
use CGI::Session;
use Config::Simple;
use Release;
use WECNnet;

# Extract the directory where the script lives
$0 =~ /^(.*)getList.cgi$/;
my $dir = $1;

# Gather variables from config file
Config::Simple->import_from($dir . 'sprung.ini', \%config);
my $host = $config{'default.host'};
my $local_port = $config{'default.local'};
my $remote_port = $config{'default.remote'};
my $user = $config{'default.user'};
my $idfile = $config{'default.idfile'};
my $queues = $config{'default.queues'};

my @printers = split(/,/, $queues);

# Re-establish session
my $cgi = new CGI;
my $sid = $cgi->cookie("SID");
my $session = new CGI::Session(undef, $sid, {Directory=>'/tmp'});

# Check if user is logged in
if (!$session->param('user')) {
  print "-1|";
  exit;
}

# establish tunnel
my $pid = setup_encrypted_tunnel($user, $host, $local_port, 
  $remote_port, $idfile);
my $socket = setup_connection($host, $remote_port);
setSocket($socket);
getLine();

print "Content-type:text/html\n\n";

# authenticate the user
$auth = connectLink($session->param('user'), $session->param('passwd'));
if (!$auth) {
  print "-1|";
  exit;
}

# retrieve list of print jobs
my @jobs = getList();

# Check if any jobs are in the queue.
if ($#jobs < 0) {
  # No jobs exist so print 0"
  print "0|";
} else {
  # Jobs exist so print the auth level of the user
  print "$auth|";

  # Print all jobs in the form "job,owner,title\n"
  foreach $val (@jobs) {
    if ($val eq "") {next;}
    print "$val->{'job'},$val->{'owner'},$val->{'title'}\n";
  }
  print "|";

  # If the user is an administrator print a list of valid printers
  if ($auth > 1) {
    foreach $val (@printers) {
      print "$val ";
    }
  }
}

`kill $pid`;
