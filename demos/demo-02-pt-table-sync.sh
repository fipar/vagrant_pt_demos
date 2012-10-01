#!/bin/bash

# demo 1:
# - all servers have SBR
# - all servers are in-sync
. /usr/local/demos/create-sandboxes.inc.sh

pause_msg "Now we'll run pt-table-sync to bring the boxes back in sync"

set -x
pt-table-sync --defaults-file=sb/master-active/my.sandbox.cnf --print --replicate=percona.checksums h=master-active,P=13306
set +x

pause_msg "But this only shows 1 of the slaves being fixed! Well, master-active only knows about it's own slaves... point to the to-be-fixed slave and use --sync-to-master:"

set -x
pt-table-sync --print --replicate=percona.checksums --sync-to-master h=slave-2,P=13309,u=demo,p=demo
set +x

pause_msg "Now we'll apply the sync (replace --print with --execute)"

set -x
pt-table-sync --execute --replicate=percona.checksums h=master-active,P=13306,u=demo,p=demo
pt-table-sync --execute --replicate=percona.checksums --sync-to-master h=slave-2,P=13309,u=demo,p=demo
set +x

pause_msg "And run checksum again to make sure things are fixed (we'll make it quicker with --databases)"

set -x
pt-table-checksum --defaults-file=$DEMOS_HOME/assets/.my.cnf --databases=world --replicate=percona.checksums --create-replicate-table --empty-replicate-table --replicate-check h=127.0.0.1,P=13306,u=demo,p=demo
pt-table-checksum --defaults-file=$DEMOS_HOME/assets/.my.cnf --databases=world --replicate=percona.checksums --replicate-check --replicate-check-only h=127.0.0.1,P=13306,u=demo,p=demo
set +x

echo "Done, above pt-table-checksum summary should show no differences"