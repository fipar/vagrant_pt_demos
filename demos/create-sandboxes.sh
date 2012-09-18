#!/bin/bash

. /usr/local/demos/create-sandboxes.inc.sh;
[ -d "$DEMOS_HOME" ] || mkdir -v $DEMOS_HOME;
# demos_list="pt-find pt-kill pt-tcp-model pt-ioprofile pt-pmp pt-align pt-log-player pt-online-schema-change pt-mysql-summary pt-config-diff pt-variable-advisor pt-duplicate-key-checker pt-mext"



# this works fine, but it's painfully slow to test
#[ -d "$SANDBOXES_HOME" ] && (for i in `ls $SANDBOXES_HOME`; do { 
#    $SANDBOXES_HOME/$i/stop; echo "stopped $i";
#} done;);

# [ -d "$DEMOS_HOME/demo-tutorial/" ] && $DEMOS_HOME/demo-tutorial/stop;
killall --verbose -9 mysqld mysqld_safe; echo "killed any remaining mysqld instance";
rm -rf $SANDBOXES_HOME; echo "cleared $SANDBOXES_HOME";
mkdir -v $SANDBOXES_HOME; echo "created $SANDBOXES_HOME";



# rm -rfv $DEMOS_HOME/demo-tutorial;
# create_demo_tutorial_box
# $DEMOS_HOME/demo-tutorial/start;

create_demo_recipes_box "master-active" 13306 log-slave-updates;
create_demo_recipes_box "master-passive" 13307 log-slave-updates read-only=1;
create_demo_recipes_box "slave-1" 13308 read-only=1;
create_demo_recipes_box "slave-2" 13309 read-only=1;

for i in `ls $SANDBOXES_HOME`; do { 
    $SANDBOXES_HOME/$i/start; 
} done;

demo_recipes_boxes_set_replication;