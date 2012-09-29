#!/bin/bash

# demo 1:
# - all servers have SBR
# - all servers are in-sync
. /usr/local/demos/create-sandboxes.inc.sh

pause_msg "We'll first enable slow log and produce some traffic with mysqlslap"

rotate_slow_log "master-active";

enable_slow_log "master-active";

since=`date +"%F %T"`
sysbench_it "master-active";
until=`date +"%F %T"`

# slow_log=`$master_active/use -B -N -e "SELECT @@global.slow_query_log_file";`
slow_log=$(get_slow_log_filename "master-active")



pause_msg "now we have something to digest in the slow log: $slow_log";

report_dest=$DEMOS_HOME/pt-query-digest.report;
set -x
pt-query-digest --since="$since" --until="$until" $slow_log --limit 10 > $report_dest
set +x

less $report_dest;

pause_msg "report stored as $report_dest";