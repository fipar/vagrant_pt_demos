#!/bin/bash

# demo 1:
# - all servers have SBR
# - all servers are in-sync
. /usr/local/demos/create-sandboxes.inc.sh

pause_msg "We now suffered another stall, let's run pt-sift again to check if pt-stalk captured something"


set -x 
pt-sift $DEMOS_HOME/output
set +x

