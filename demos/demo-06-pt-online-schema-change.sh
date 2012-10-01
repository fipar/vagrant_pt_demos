#!/bin/bash

# demo 1:
# - all servers have SBR
# - all servers are in-sync
. /usr/local/demos/create-sandboxes.inc.sh

report_dest=$DEMOS_HOME/output/pt-query-digest.report;
echo "Besides conclusions we reached from pt-sift, we observed high count of on-disk tmp tables on the slow queries report:"
grep -A22 "737F39F04B198EF6" $report_dest ;
echo ""
echo "quick investigation reveals TEXT field being used unnecessarily "
$master_active/use -v -t -e "SHOW CREATE TABLE sbtest.sbtest1\G"
echo ""
echo "We'll use pt-online-schema-change to fix without impacting other threads using the table"
echo "(we'll stop replication on slave-1 before, so we can use that for comparison later)"
pause_msg "";

$slave_1/use -e "STOP SLAVE";
set -x
pt-online-schema-change --dry-run --alter "ADD INDEX id_c(id,c), MODIFY COLUMN c VARCHAR(127)" h=master-active,P=13306,u=demo,p=demo,D=sbtest,t=sbtest1

pause_msg "the above dry-run looks fine, so we'll proceed with the change"
pt-online-schema-change --execute --alter "ADD INDEX id_c(id,c), MODIFY COLUMN c VARCHAR(127)" h=master-active,P=13306,u=demo,p=demo,D=sbtest,t=sbtest1
