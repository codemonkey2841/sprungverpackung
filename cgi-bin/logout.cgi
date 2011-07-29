#!/usr/bin/perl -t

########
#
# Filename:        logout.cgi
# Project:         Sprungverpackung
# Number of Files: 12
# Language:        Perl/CGI
# Platform:        N/A
# Summary:         Destroys the current users session
#
########

use CGI;
use CGI::Session;

# Re-establish session
my $cgi = new CGI;
my $sid = $cgi->cookie("SID");
my $session = new CGI::Session(undef, $sid, {Directory=>'/tmp'});
$session->clear();
print $cgi->redirect(-status=>'302 Moved', -uri=>'/sprung/index.html');
