#!/bin/bash
# Authored by Marcos Albe (markus.albe@gmail.com). Minor edits by Fernando Ipar (fipar@acm.org)
# Creates the sandboxes used for demos (stopping them and removing their contents first if needed), loading the sample datasets into them.
# DISCLAIMER: This SIGKILLs any running mysqld instance, removes datadirs, and has no test cases. Use only on test systems.
. /usr/local/demos/create-sandboxes.inc.sh;

pause_msg "Create demo sandboxes y/N? "

[ "$REPLY" == "y" ] && {
    [ -d "$DEMOS_HOME" ] || mkdir -v $DEMOS_HOME;
    # demos_list="pt-find pt-kill pt-tcp-model pt-ioprofile pt-pmp pt-align pt-log-player pt-online-schema-change pt-mysql-summary pt-config-diff pt-variable-advisor pt-duplicate-key-checker pt-mext"

    kill_mysql

    rm -rf $SANDBOXES_HOME
    echo "cleared $SANDBOXES_HOME"

    mkdir -v $SANDBOXES_HOME
    echo "created $SANDBOXES_HOME"

    create_demo_box "master-active" 13306 log-slave-updates;
    create_demo_box "master-passive" 13307 log-slave-updates read-only=1;
    create_demo_box "slave-1" 13308 read-only=1;
    create_demo_box "slave-2" 13309 read-only=1;

    start_instance "master-active"
    load_sample_databases "master-active";
    $SANDBOXES_HOME/master-active/use -e "RESET MASTER";
    $SANDBOXES_HOME/master-active/use -e "CREATE DATABASE IF NOT EXISTS percona;";
    backup_generic_datadir;

    demo_recipes_boxes_reset_data_and_replication

    cd $DEMOS_HOME;

    # for i in `ls $SANDBOXES_HOME`; do
    #    $SANDBOXES_HOME/$i/start
    #    load_generic_datadir $i
    # done
}