#!/bin/bash

# demo 1:
# - all servers have SBR
# - all servers are in-sync
. /usr/local/demos/create-sandboxes.inc.sh

pause_msg "On-line ALTER TABLE with pt-online-schema-change:"



$master_active/use -B -N -e "SHOW CREATE TABLE ";

