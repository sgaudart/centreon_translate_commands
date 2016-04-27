# centreon_translate_commands

IN YOUR CENTREON CENTRAL SERVER :
This script translate for each service the command used. <br>
The command is written in the field comment of each service (you need to use the option --user and --password)

## Requirement

  - Centreon Central
  - Perl
  - mysql client
  - CLAPI module

## Options
```erb
[--user and --password] : CLAPI user if you want to WRITE the command into the service's comment
[--verbose]
[--serviceid] : run only for this service_id 
```

## Examples 

Pour voir une commande pour un service particulier (il faut connaitre son ID) :
```erb
# ./centreon_translate_commands.pl --service 18218
[Wed Apr 27 12:02:29 2016] [INFO] Translation beginning...
[Wed Apr 27 12:02:29 2016] [INFO] comment{18218}=/usr/lib/nagios/plugins/check_mysql_slavestatus.sh -H ************* -P 3306 -u replication -p *************
[Wed Apr 27 12:02:29 2016] [INFO] command{18218}=/usr/lib/nagios/plugins/check_mysql_slavestatus.sh -H ************* -P 3306 -u replication -p  *************
[Wed Apr 27 12:02:29 2016] [INFO] Translation finished...

```

