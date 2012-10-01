#!/bin/bash

# demo 1:
# - all servers have SBR
# - all servers are in-sync
. /usr/local/demos/create-sandboxes.inc.sh

pause_msg "We'll now stop replication in slave-1, and use it as \"upgraded\" server
to demonstrate pt-online-schema-change and pt-upgrade.  We'll see pt-osc effectively
replicating to the other nodes of the replication setup (master-passive, slave-2)
and we'll keep slave-1 as the one where upgrade is being tested.)"

# $master_active/use -v -t -e "STOP SLAVE";
# $master_passive/use -v -t -e "STOP SLAVE";
$slave_1/use -v -t -e "STOP SLAVE";


slow_log=$(get_slow_log_filename "master-active")
pt-upgrade $slow_log h=master-active,P=13306,u=demo,p=demo h=slave-1,P=13307,u=demo,p=demo









since=`date +"%F %T"`
slap_it "master-active";
until=`date +"%F %T"`

slow_log=`$master_active/use -B -N -e "SELECT @@global.slow_query_log_file";`

pause_msg "now we have stuff to digest in $slow_log";

set -x
pt-query-digest --since="$since" --until="$until" $slow_log --limit 10
set +x
