#!/bin/bash

# demo 1: 
# - all servers have SBR
# - all servers are in-sync
. /usr/local/demos/create-sandboxes.inc.sh

demo_recipes_boxes_reset_data_and_replication

master_active="$SANDBOXES_HOME/master-active/";
master_passive="$SANDBOXES_HOME/master-passive/";
slave_1="$SANDBOXES_HOME/slave-1/";
slave_2="$SANDBOXES_HOME/slave-2/";

set -x
# defaults file should work (https://bugs.launchpad.net/percona-toolkit/+bug/1046329) but doesn't :P 
$master_active/use -v -t -e "CREATE DATABASE IF NOT EXISTS percona;";
pt-table-checksum --defaults-file=$DEMOS_HOME/assets/.my.cnf --replicate=percona.checksums --create-replicate-table --empty-replicate-table h=127.0.0.1,P=13306,u=demo,p=demo
pt-table-checksum --defaults-file=$DEMOS_HOME/assets/.my.cnf --replicate=percona.checksums --replicate-check --replicate-check-only h=127.0.0.1,P=13306,u=demo,p=demo
set +x

echo "above table should show zero differences;"



# demo 2
# - produce some independent differences in slaves
# - all servers have SBR

set -x
$slave_2/use -v -t -e "INSERT INTO world.Country VALUES ('RSY', 'Republica Separatista de Young', 'South America', 'South America', 40, 1837, 15797, 75.2, 20831, 19967, 'Young', 'Republic', 'Ignacio Nin', 3492, 'YO')";
$slave_1/use -v -t -e "INSERT INTO world.City VALUES (NULL, 'Las Flores', 'URY', 'Maldonado', 200)";

pt-table-checksum --defaults-file=$DEMOS_HOME/assets/.my.cnf --replicate=percona.checksums --create-replicate-table --empty-replicate-table --replicate-check  h=127.0.0.1,P=13306,u=demo,p=demo
pt-table-checksum --defaults-file=$DEMOS_HOME/assets/.my.cnf --replicate=percona.checksums --replicate-check --replicate-check-only h=127.0.0.1,P=13306,u=demo,p=demo
set +x

echo "above table should show 2 difference;"

