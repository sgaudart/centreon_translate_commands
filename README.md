# centreon_translate_commands

IN YOUR CENTREON CENTRAL SERVER :
This script translate for each service the command used. <br>
The command is written in the field comment of each service (you need to use the option --user and --password)

## Requirement

  - Centreon Central
  - Perl
  - mysql client
  - CLAPI module

## Tested with...

Centreon 2.5.4 et 2.6.6

## Options
```erb
[--user and --password] : CLAPI user if you want to WRITE the command into the service's comment
[--verbose]
[--serviceid] : run only for this service_id 
```

## Examples 

Show a command for a specific service (your must know the ID service, for example 18218) :
```erb
# ./centreon_translate_commands.pl --service 18218
[Wed Apr 27 12:02:29 2016] [INFO] Translation beginning...
[Wed Apr 27 12:02:29 2016] [INFO] comment{18218}=/usr/lib/nagios/plugins/check_mysql_slavestatus.sh -H ************* -P 3306 -u replication -p *************
[Wed Apr 27 12:02:29 2016] [INFO] command{18218}=/usr/lib/nagios/plugins/check_mysql_slavestatus.sh -H ************* -P 3306 -u replication -p  *************
[Wed Apr 27 12:02:29 2016] [INFO] Translation finished...
```

Translate the commands for every service but NOT WRITE into the comment's field :
```erb
# ./centreon_translate_commands.pl
[Wed Apr 27 12:02:29 2016] [INFO] Translation beginning...
[Fri Apr 22 09:00:48 2016] [VERB] comment{15294}=NULL
[Fri Apr 22 09:00:48 2016] [VERB] command{15294}=/usr/lib/nagios/plugins/check_snmp_mib2.pl -H *******  --snmp-version 2c --rocommunity ****  --uptime -c 15
...etc
[Wed Apr 27 12:03:29 2016] [INFO] Translation finished...
```

Translate the commands for every service and WRITE into the comment's field (if comment translated command):
```erb
# ./centreon_translate_commands.pl --user <clapi_user> --password <clapi_password>
[Wed Apr 27 12:02:29 2016] [INFO] Translation beginning...
[Fri Apr 22 09:05:51 2016] [VERB] comment{22044}=NULL
[Fri Apr 22 09:05:51 2016] [VERB] command{22044}=/usr/lib/nagios/plugins/check_wmi_plus.pl -H ******* -m checkmem -u nagios -p ****** -w 110 -c 120  -t 30
...etc
[Wed Apr 27 12:03:29 2016] [INFO] Translation finished...
```

