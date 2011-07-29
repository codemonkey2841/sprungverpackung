########
#
# Filename:        WECNnet.pm
# Project:         Sprungverpackung
# Number of Files: 12
# Language:        Perl
# Platform:        Linux
# Summary:         Contains all the functions required to invoke an encrypted 
#                  tunnel and sockets
#
########

$ENV{PATH} = "/bin";
use IO::Socket::INET;

####################
#
# setup_encrypted_tunnel - establishes an encryped tunnel between
#  this machine and the remote machine.
#
# params:
#  user - the user name to connect as
#  host - the host to connect to
#  local_port - the port on this end of the tunnel
#  remote_port - the port on the remote end of the tunnel
#  ident_file - the identity file for passwordless authentication
#  passwd - the password of the user
#
# returns:
#  the PID of the tunnel
#
####################

sub setup_encrypted_tunnel {
  my $user        = shift;
  my $host        = shift;
  my $local_port  = shift;
  my $remote_port = shift;
  my $ident_file  = shift;
  my $passwd    = shift;

  if ($user =~ /(\w+)/) {$user = $1;} else {$user = "";}
  if ($host =~ /([\w\d.]+)/) {$host = $1;} else {$host = "";}
  if ($local_port =~ /(\d+)/) {$local_port = $1;}
  if ($remote_port =~ /(\d+)/) {$remote_port = $1;}

  my $dashi;
  if ($ident_file =~ /([\w.\/]+)/) {$dashi = "-i $1";}
  else {$dashi = "";}
  
  if ($passwd =~ /([\w\!\@\#\$\%\^\&\*\d]+)/) {$passwd = "-pw $1";}
  else {$passwd = "";}

  my $dashL = "-L $local_port:localhost:$remote_port";

  my $pid = fork();
  if(!$pid){
    if ($^O eq "MSWin32") {
      exec "plink -2 $passwd -N $dashL $user\@$host" or die;
    } else {
      exec "/usr/bin/ssh -2NT $dashL $dashi $user\@$host" or die;
    }
  }
  return $pid;
}

####################
#
# setup_net - Establishes a secure tunnel and a local socket
#
# params:
#  host - the remote host to connect the tunnel to
#  local_port - the port that the local end of the secure tunnel
#               is attached to.
#  remote_port - the port that the remote end of the secure tunnel
#                is attached to.
#
# returns:
#  A reference to the newly created socket
#
####################

sub setup_net {
   my $host        = shift ;
   my $local_port  = shift;
   my $remote_port = shift;

   setup_encrypted_tunnel($host, $local_port, $remote_port);
   my $socket = setup_connection("127.0.0.1",$local_port);
   return $socket;
}

####################
#
# setup_connection - Creates a socker to the remote host.
#
# params:
#  host - the host machine to create the socket to
#  port - the port on host to connect to
#
# returns:
#  a reference to the newly created socket to host.
#
####################

sub setup_connection {
   my $host = shift;
   my $port = shift;

   my $sock = new IO::Socket::INET(
      PeerAddr => $host,
      PeerPort => $port,
      Proto    => 'tcp'
   );
   return $sock;
}
1;
__END__
