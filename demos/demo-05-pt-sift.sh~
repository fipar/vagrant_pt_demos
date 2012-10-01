#!/bin/bash

# demo 1:
# - all servers have SBR
# - all servers are in-sync
. /usr/local/demos/create-sandboxes.inc.sh

pause_msg "We'll first enable slow log and produce some traffic with mysqlslap"



enable_slow_log "master-active";

since=`date +"%F %T"`
slap_it "master-active";
until=`date +"%F %T"`

slow_log=`$master_active/use -B -N -e "SELECT @@global.slow_query_log_file";`

pause_msg "now we have stuff to digest in $slow_log";

set -x
pt-query-digest --since="$since" --until="$until" $slow_log --limit 10
set +x
