#!/usr/bin/perl
#======================================================================
# Auteur : sgaudart@capensis.fr
# Date   : 22/03/2016
# But    : [CENTREON REQUIRED] This script translate the command used for each service.
#          The command is written in the field comment of each service.
# INPUT : 
#          --user + --password : information for CLAPI commands
# OUTPUT :
#          CLAPI commands (command written in the field comment)
#
#======================================================================
#   Date      Version    Auteur       Commentaires
# 22/03/2016  1          SGA          initial version
# 29/03/2016  2          SGA          add option --serviceid
# 05/04/2016  3          SGA          add option --user and --password
# 08/04/2016  4          SGA          better algo to get a correct services list
# 11/05/2016  5          SGA          enhancement for the sql request for command
#======================================================================

use strict;
use warnings;
use Getopt::Long;
use Time::Local;

my $verbose;
my $help;
my $serviceid="";
my $clapiuser=""; # user for CLAPI
my $clapipass=""; # user for CLAPI

GetOptions (
"user=s" => \$clapiuser, # string
"password=s" => \$clapipass, # string
"serviceid=i" => \$serviceid, # integer
"verbose" => \$verbose, # flag
"help" => \$help) # flag
or die("Error in command line arguments\n");

my $line;
my $centreon_conf="/etc/centreon/centreon.conf.php"; 

my $hostCentstorage; # sql information 
my $user; # sql information 
my $password; # sql information 
my $dbcstg; # sql information 
my $db; # sql information
my $sqlprefix = "";
my $sqlrequest = "";

my $sqlline=0; # line counter
my %command; # store the translate command (ex: $command{$service_id}=...)
my %comment; # store the comment (ex: $comment{$service_id}=...)
my %activate; # store the service_activate

###############################
# HELP
###############################

if ($help)
{
	print"[CENTREON REQUIRED] This script translate for each service the command used.
The command is written in the field comment of each service.
options : [--user & --password] : CLAPI user if you want to WRITE the command into the service's comment
          [--verbose]
          [--serviceid] : run only for this service_id\n";
	exit;
}

LogMessage("[INFO] Translation beginning...");
###############################
# READING THE CENTREON CONF FILE
###############################

#$conf_centreon['hostCentstorage'] = "XX.YY.ZZ.XX";
#$conf_centreon['user'] = "centreon";
#$conf_centreon['password'] = "XXXXXXXXX";
#$conf_centreon['db'] = "centreon";
#$conf_centreon['dbcstg'] = "centreon_storage";
open (CENTREONFD, "$centreon_conf") or die "Can't open centreon conf  : $centreon_conf\n" ; # reading
while (<CENTREONFD>)
{
	$line=$_;
	chomp($line); # delete the carriage return
	if ($line =~ /^\$conf_centreon\['hostCentstorage'\] = "(.*)";$/) { $hostCentstorage = $1; }
	if ($line =~ /^\$conf_centreon\['user'\] = "(.*)";$/) { $user = $1; }
	if ($line =~ /^\$conf_centreon\['password'\] = "(.*)";$/) { $password = $1; }
	if ($line =~ /^\$conf_centreon\['db'\] = "(.*)";$/) { $db = $1; }
	if ($line =~ /^\$conf_centreon\['dbcstg'\] = "(.*)";$/) { $dbcstg = $1; }
}
close CENTREONFD;

###############################
# PREPARING THE SQL QUERY FOR THE COMMENT FIELD
###############################

$sqlprefix = "mysql --batch -h $hostCentstorage -u $user -p$password -D $db -e";
if ($serviceid eq "")
{
	$sqlrequest = "SELECT service_id,service_comment,service_activate FROM service";
}
else
{
	$sqlrequest = "SELECT service_id,service_comment,service_activate FROM service WHERE service_id=$serviceid";
}

###############################
# RUN THE SQL QUERY FOR THE COMMENT FIELD
###############################

#print "[COMMENT] sqlrequest = $sqlrequest\n" if $verbose;
#print "[COMMENT] sql request processing ($user\@$hostCentstorage) " if $verbose;
system "$sqlprefix \"$sqlrequest;\" > comment";
#print "finished...\n" if $verbose;

###############################
# READING THE SQL RESULT
###############################

open (COMMENT, "comment") or die "Can't open file comment\n" ; # reading the comment
while (<COMMENT>)
{
	$sqlline++; # line counter
	if ($sqlline eq 1) { next; } # next if the first line
	$line=$_;
	chomp($line); # delete the carriage return
	my ($service_id, $service_comment, $service_activate) = split('\t', $line);
	
	$comment{$service_id}=$service_comment;
	$activate{$service_id}=$service_activate;
	LogMessage("[INFO] comment{$service_id}=$comment{$service_id}") if ($serviceid ne "");

}
close COMMENT;

###############################
# PREPARING THE SQL QUERY FOR THE TRANSLATE COMMAND
###############################

$sqlprefix = "mysql --batch -h $hostCentstorage -u $user -p$password -D $dbcstg -e"; # use centreon_storage database
if ($serviceid eq "")
{
	$sqlrequest = "SELECT hosts.name,services.description,services.service_id,services.command_line FROM services,hosts WHERE hosts.host_id=services.host_id AND hosts.enabled=1 AND services.enabled=1 ORDER BY service_id";
}
else
{
	$sqlrequest = "SELECT hosts.name,services.description,services.service_id,services.command_line FROM services,hosts WHERE hosts.host_id=services.host_id AND hosts.enabled=1 AND services.enabled=1 AND service_id=$serviceid ORDER BY service_id";
}

###############################
# RUN THE SQL QUERY FOR THE TRANSLATE COMMAND
###############################

#print "[COMMAND] sqlrequest = $sqlrequest\n" if $verbose;
#print "[COMMAND] sql request processing ($user\@$hostCentstorage) " if $verbose;
system "$sqlprefix \"$sqlrequest;\" > command";
#print "finished...\n" if $verbose;

###############################
# READING THE SQL RESULT AND PROCESSING THE VALUES
###############################

$sqlline=0;
open (COMMAND, "command") or die "Can't open command\n" ; # reading the translate command
while (<COMMAND>)
{
	$sqlline++; # line counter
	if ($sqlline eq 1) { next; } # next if the first line
	$line=$_;
	chomp($line); # delete the carriage return
	my ($host_name, $service_descr, $service_id, $command_line) = split('\t', $line);
	$command{$service_id}=$command_line;
	
	if (!(defined $comment{$service_id})) { next; } # SERVICE INEXISTANT
	LogMessage("[INFO] command{$service_id}=$command{$service_id}") if ($serviceid ne "");
	
	if ($command{$service_id} ne $comment{$service_id})
	{
		# COMMENT IS NOT THE COMMAND => PROCESSING THE TRANSLATED COMMAND FOR THIS SERVICE
		LogMessage("[INFO] command is different from the commentary service #$service_id : $host_name | $service_descr");
		LogMessage("[VERB] comment{$service_id}=$comment{$service_id}") if $verbose;
		LogMessage("[VERB] command{$service_id}=$command{$service_id}") if $verbose;
		if ($clapiuser ne "")
		{
			# WE STORE THE COMMAND INTO THE COMMENT'S SERVICE
			$command{$service_id} =~ s/\"/\\\"/g; # substitution des chr " => \"
			LogMessage("[INFO] write command into the comment's field");
			LaunchAndLog("centreon -u $clapiuser -p $clapipass -o SERVICE -a setparam -v \"$host_name;$service_descr;comment;$command{$service_id}\"");
		}
	}

}
close COMMAND;

LogMessage("[INFO] Translation finished...");
# --- END


###############################
# FUNCTIONS
###############################

sub LaunchAndLog # lance une commande system et log le resultat si erreur
{
	my $command = shift;
	my $now_string = localtime;
	system($command) == 0
		or LogMessage("[ERROR] $command failed: Error $?");
}

sub LogMessage # ecrit un string dans un fichier de log avec date+heure
{
	my $line = shift;
	my $now_string = localtime;
	# WRITING LOG FILE
	print "[$now_string] $line\n";
}
