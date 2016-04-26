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
options : [--user & --password] : CLAPI user if you want to WRITE the command into the service's comment <br>
          [--verbose] <br>
          [--serviceid] : run only for this service_id <br>

