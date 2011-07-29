########
#
# Filename:        Release.pm
# Project:         Sprungverpackung
# Number of Files: 12
# Language:        Perl
# Platform:        N/A
# Summary:         The perl module containing the functions to interact with 
#                  the Release server.
#
########
use lib "./";
use Switch;
use WECNnet;

my $socket;

########
#
# setSocket - sets the socket variable to the specified socket
#
# params
#  socket - the socket to set as the global socket
#
########
sub setSocket {
  
  $socket = shift;

} # end of setSocket method

###########
#
# connectLink - connects this client to the released server
#
# params
#  $user - the user name of the user to authenticate as
#  $passwd - the password of the user provided
#
# returns
#  true if connection was established, false if failed and NULL if and unknown 
#  error occurs
#
###########
sub connectLink {

  my $user = shift;
  my $passwd = shift;
  sendLine("AUTH $user $passwd");
  chomp(my $resp = getLine());
  if ($resp eq "BAD") {
    return 0;
  } elsif ($resp eq "OK") {
    return 1;
  } elsif ($resp eq "ADMOK") {
    return 2;
  }
  return;
  
} # end of connect method

###########
#
# getList - retrieves a list of jobs in the print queue
#           that the authenticated user is authorized to view
#
# params
#  none
#
# returns
#  an array of hashes including the job info 'job', 'title', 'owner'
#
###########
sub getList {

  sendLine("GET");
  my @jobs = ();
  while (($line = getLine()) !~ /^OK/) {
    if ($line =~ /^LIST (.*)/) {
      @temp = split(/\ /, $1);
      my $hash;
      $hash->{'job'} = $temp[0];
      $hash->{'owner'} = $temp[1];
      $hash->{'title'} = $temp[2];
      push(@jobs, $hash);
    }
    elsif ($line eq "BAD Not Authenticated") {
      doAuth();
      redo;
    }
    else {
      print "$line\n";
      last;
    }
  }
  return @jobs;

} # end of getList method

###########
#
# printJob - requests the specified print job be printed to
#            the specified printer.
#
# params
#  $job - the job ID(s) of the job(s) to be printed
#  $printer - the name of the printer to print to
#
###########
sub printJob {

  my $job = shift;
  my $printer = shift;
  sendLine("TRANSFER $job $printer");
  return getLine();

} # end of printJob method

###########
#
# sendLine - sends a message to the server over the designated socket
#
# params
#  $line - the message to send
#
###########
sub sendLine {

  my $line = shift;
  print $socket "$line\n";

} # end of sendLine method

###########
#
# getLine - retrieves information from the specified socket
#
# params
#  none
#
# returns
#  a string sent by the server over the specified socket
#
###########
sub getLine {

  my $line = <$socket>;
  chomp($line);
  return $line;

} # end of getLine method

###########
#
# doCmd - parses and executes commands from the user
#
# params
#  none
#
###########
sub doCmd {

  print "> ";
  chomp($cmd = <STDIN>);
  switch ($cmd) {
    case /^list/i {
      @list = getList();
      print "Job\tOwner\tDescription\n";
      foreach $pod (@list) {
        print $pod->{'job'} . "\t";
        print $pod->{'owner'} . "\t";
        print $pod->{'title'} . "\n";
      }
    }
    case /^print/i {
      $cmd =~ /^print\ ?(.*)/i;
      my $job;
      my $printer;
      my $a = $1;
      if ($a =~ /\ /) {
        ($job, $printer) = split(/\ /, $a);
      } else {
        print "Which job do you wish to print? ";
        chomp($job = <STDIN>);
        print "Which printer do you wish to print to? ";
        chomp($printer = <STDIN>);
      }
      $job = scrubString($job, '[\d]');
      $printer = scrubString($printer, '[\w\d]');
      print printJob($job, $printer), "\n";
    }
    case /^exit/i {
      return 0;
    }
    case /^help/i {
      print "You may type the following commands:\n";
      print "\tlist - lists the jobs of the current authenticated user\n";
      print "\tprint - indicates you want to print a job, you may\n";
      print "\t\tspecify the job and printer in this command.\n";
      print "\tdelete - indicates you want to delete a job, you may\n";
      print "\t\tspecify the job to delete in this command.\n";
      print "\thelp - prints this\n";
      print "\texit - exits the program\n";
    }
  }
  return 1;

} # end of doCmd method

###########
#
# scrubString - Truncates the given string to the first set of valid
#   characters in the string.
#
# params:
#  str - the string to be acted upon
#  regex - a REGEX pattern listing all valid characters for this action.
#
# returns:
#  The sanitized version of str, or
#  "Invalid string" if no valid characters were found.
#
###########

sub scrubString {
  
  my $str = shift;
  my $regex = shift;
  if ($str =~ /($regex+)/) {return $1;}
  else {print "Invalid string\n";}

} # end of scrubString method
1;
