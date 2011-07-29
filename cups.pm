##########
#
# Filename:        cups.pm
# Project:         Sprungverpackung
# Number of Files: 12
# Language:        Perl
# Platform:        Linux
# Summary:         This module gives Perl scripts functionality to control
#                  a Cups installation.
#
##########
use POSIX;

$lp     = `which lp`;
$lpmove = `which lpmove`;
$lprm   = `which lprm`;
$lpq    = `which lpq`;
$lpstat = `which lpstat`;

$queue = "dummy";

##########
#
# move_job - Moves a job from the holding queue to the printer
#
# params
#  id - the ID of the job to move
#  printer - the name of the printer to send the job to
#
##########
sub move_job {

   my $id      = shift;
   my $printer = shift;

   system("$lpmove $id $printer");
   system("$lp -H resume -i $id");

} # end of move_job method

##########
#
# delete_job - Remove a job from the queue
#
# params
#  id - The ID of the job to remove
#
# returns
#  The system message from the lprm command
#
##########
sub delete_job {

   my $id = shift;
   return system("$lprm $id");

} # end of delete_job method

##########
#
# rtrim - Removes all whitespace on the right side of a string
#
# params
#  string - The string to strip the whitespace from
#
# returns
#  the stripped string
#
##########
sub rtrim($) {

   my $string = shift;
   $string =~ s/\s+$//;
   return $string;

} # end of rtrim method

##########
#
# list_jobs - Retrieves a list of jobs from a printer
#
# params
#  printer - the printer to get the job list from
#
# returns
#  a hash of jobs and job info keyed by the job ID
#
##########
sub list_jobs {

   my $printer = shift;
   my %jobinfo = ();

   # Load hash with jobs and job owners
   open(FILE,"$lpq -P $printer|grep bytes|");
   while(<FILE>){
      $id    = substr($_,16,8);
      ($id)  = split(" ",$id);
      $name  = substr($_,24,32);
      $name  = rtrim($name);
      $jobinfo{$id}->{name} = $name;
   }
   close(FILE);

   # Stat jobs from the printer to gather the rest of the info
   open(FILE,"$lpstat -P $printer|");
   while(<FILE>){
      ($long_id,$owner,$size,$week_day,$day,$month,$year,$time,$am_pm,$tz) =
      split(" ");
      ($hour,$min,$sec) = split(":", $time);
      ($printer,$id) = split("-",$long_id);

      if ($month eq "Jan") {$month = 0;}
      elsif ($month eq "Feb") {$month = 1;}
      elsif ($month eq "Mar") {$month = 2;}
      elsif ($month eq "Apr") {$month = 3;}
      elsif ($month eq "May") {$month = 4;}
      elsif ($month eq "Jun") {$month = 5;}
      elsif ($month eq "Jul") {$month = 6;}
      elsif ($month eq "Aug") {$month = 7;}
      elsif ($month eq "Sep") {$month = 8;}
      elsif ($month eq "Oct") {$month = 9;}
      elsif ($month eq "Nov") {$month = 10;}
      elsif ($month eq "Dec") {$month = 11;}
      $year -= 1900;
      
      $timestamp = mktime($sec,$min,$hour,$day,$month,$year);
      $jobinfo{"$id"}->{owner} = $owner;
      $jobinfo{"$id"}->{size}  = $size;
      $jobinfo{"$id"}->{timestamp} = $timestamp;
  }

  return %jobinfo;

} # end of list_jobs method
1;
__END__
