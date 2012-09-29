#!/bin/bash

# demo 1:
# - all servers have SBR
# - all servers are in-sync
. /usr/local/demos/create-sandboxes.inc.sh

pause_msg "We'll now stop replication between masters, and use them to demonstrate pt-upgrade
We'll introduce a configuratoin change in one of the masters, which should produce noticeable difference"

$master_active/use -v -t -e "STOP SLAVE";
$master_passive/use -v -t -e "STOP SLAVE";

set_flush_at_trx "master-passive" 1









since=`date +"%F %T"`
slap_it "master-active";
until=`date +"%F %T"`

slow_log=`$master_active/use -B -N -e "SELECT @@global.slow_query_log_file";`

pause_msg "now we have stuff to digest in $slow_log";

set -x
pt-query-digest --since="$since" --until="$until" $slow_log --limit 10
set +x
