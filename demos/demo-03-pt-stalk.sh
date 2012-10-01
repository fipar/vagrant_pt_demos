#!/bin/bash

# demo 1:
# - all servers have SBR
# - all servers are in-sync
. /usr/local/demos/create-sandboxes.inc.sh

pause_msg "During unknown origin stalls, we run pt-stalk without \"stalking\" to quickly grab all the possible information while the problem is happening"
[ -d /tmp/old-ps-stalk-output ] || mkdir /tmp/old-ps-stalk-output 
sudo pkill -f "bash /usr/bin/pt-stalk"
sudo mv $DEMOS_HOME/output/2012* /tmp/old-ps-stalk-output 

t0=`date +%s`
set -x
sudo pt-stalk --no-stalk \
  --dest=$DEMOS_HOME/output \
  --log=$DEMOS_HOME/output/pt-stalk.log \
  --pid=$DEMOS_HOME/output/pt-stalk.pid \
  --run-time=10 \
  -- --defaults-file=$SANDBOXES_HOME/master-active/my.sandbox.cnf
set +x

pause_msg "Now pt-stalk is running; We wait --run-time seconds and then we can check in $DEMOS_HOME/output, for which we'll use pt-sift"

t1=$(( 10 - (`date +%s` - $t0) ));

[ $t1 -gt 0 ] && {
  echo "sleeping $t1 seconds while pt-stalk runs";
  sleep $t1;
}

set -x 
pt-sift $DEMOS_HOME/output
set +x


set -x
sudo pt-stalk --daemonize \
  --dest=$DEMOS_HOME/output \
  --log=$DEMOS_HOME/output/pt-stalk.log \
  --pid=$DEMOS_HOME/output/pt-stalk.pid \
  --run-time=10 \
  --disk-bytes-free=2G \
  --function=status \
  --variable=Threads_running \
  --threshold=20 \
  --cycles=3 \
  -- --defaults-file=$SANDBOXES_HOME/master-active/my.sandbox.cnf
set +x

echo "we can check status by tail'ing the log file:"
tail -f $DEMOS_HOME/output/pt-stalk.log
