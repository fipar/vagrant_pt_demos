#!/bin/bash

# demo 1:
# - all servers have SBR
# - all servers are in-sync
. /usr/local/demos/create-sandboxes.inc.sh


[ "$1" == "reset-boxes" ] && demo_recipes_boxes_reset_data_and_replication;

pause_msg "Running checksum demo"

set -x

$master_active/use -v -t -e "CREATE DATABASE IF NOT EXISTS percona;";
checksum_slaves
set +x

pause_msg "Above table should show zero differences; we'll now insert some rows into world.Country and world.City through the slaves"


# demo 2
# - produce some independent differences in slaves
# - all servers have SBR

set -x
poison_slaves
checksum_slaves
set +x



