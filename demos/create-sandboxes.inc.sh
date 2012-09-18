#!/bin/bash

# set DEMOS_HOME to the place where the demos/ subdirectory lives in your host. As I plan to run this from that dir, I'll just set it to $PWD
export DEMOS_HOME=/usr/local/demos
# change this if you want, this is where sandboxes will be created
export SANDBOXES_HOME="$DEMOS_HOME/sb";
# set this to the path where your MySQL version lives. A MySQL binary directory should recide under this path (i.e. /usr/local/5.5.27)
export BINARY_BASE="/usr/local"
# you shouldn't need to change anything below this comment

export PTBIN="$DEMOS_HOME/bin/";

die() {
    echo $* >&2
    exit 1
}

create_demo_tutorial_box () {
mkdr -p $DEMOS_HOME/assets/servers/5.5
make_sandbox $DEMOS_HOME/assets/servers/ \
    --upper_directory="$SANDBOXES_HOME" --sandbox_directory="demo-tutorial" --no_ver_after_name \
    --datadir_from="dir:${DEMOS_HOME}/assets/loaded-datadir/" \
    --no_show --sandbox_port=3301 --db_user=demo --db_password=demo \
    --my_clause="innodb_buffer_pool_size=1024M" \
    --my_clause="innodb_log_file_size=64M" \
    --my_clause="innodb_file_per_table" \
    --my_clause="innodb_flush_log_at_trx_commit=2" \
    $MYSQL_BINARY_INSTALL
}

# $1 = box name
# $2 = port
# $3 = my_clause
create_demo_recipes_box () {
    extra="";
    [ -z "$3" ] || extra="--my_clause=${3}";
    [ -z "$4" ] || extra="$extra --my_clause=${4}";
    [ -z "$5" ] || extra="$extra --my_clause=${5}";
    make_sandbox  5.5.27 -- \
        --upper_directory="$SANDBOXES_HOME" --sandbox_directory="$1" --no_ver_after_name \
        --no_show --sandbox_port=$2 --db_user=demo --db_password=demo --repl_user=demo --repl_password=demo \
        --my_clause="innodb_buffer_pool_size=128M" \
        --my_clause="innodb_log_file_size=64M" \
        --my_clause="innodb_file_per_table" \
        --my_clause="innodb_fast_shutdown=2" \
        --my_clause="innodb_flush_log_at_trx_commit=2" \
        --my_clause="log-bin=$1-bin" \
        --my_clause="binlog-format=STATEMENT" \
        --my_clause="skip-slave-start" \
        --my_clause="report-host=127.0.0.1" \
        --my_clause="report-port=$2" \
        --my_clause="server-id=$2" \
        $extra
}

demo_recipes_boxes_reset_data_and_replication () {
    if [ -d "$SANDBOXES_HOME" ];
    then
        killall --verbose -9 mysqld mysqld_safe; echo "killed any remaining mysqld instance";
        for i in `ls $SANDBOXES_HOME`; do {
            # $SANDBOXES_HOME/$i/stop; echo "stopped $i";
            rm -rf $SANDBOXES_HOME/$i/data/; echo "rm -rf $SANDBOXES_HOME/$i/data/" 
            cp -a $DEMOS_HOME/assets/loaded-datadir/ $SANDBOXES_HOME/$i/data/; echo "restored binary backup ($DEMOS_HOME/assets/loaded-datadir/)"
            $SANDBOXES_HOME/$i/start; echo "";

        } done;
        demo_recipes_boxes_set_replication;
    else
        $DEMOS_HOME/create-sandboxes.sh;A
    fi
}

demo_recipes_boxes_set_replication () {
    CHANGE_MASTER_COMMON_SQL="CHANGE MASTER TO MASTER_HOST='127.0.0.1', MASTER_USER='demo', MASTER_PASSWORD='demo', MASTER_LOG_POS=107"
    START_SLAVE_SQL="SLAVE START; SELECT SLEEP(0.5); SHOW SLAVE STATUS\G SHOW MASTER STATUS; SHOW SLAVE HOSTS;"

    $SANDBOXES_HOME/master-active/use -v -t -e "$CHANGE_MASTER_COMMON_SQL, MASTER_LOG_FILE='master-passive-bin.000001', MASTER_PORT=13307;  $START_SLAVE_SQL";
    $SANDBOXES_HOME/master-passive/use -v -t -e "$CHANGE_MASTER_COMMON_SQL, MASTER_LOG_FILE='master-active-bin.000001', MASTER_PORT=13306;  $START_SLAVE_SQL";
    $SANDBOXES_HOME/slave-1/use -v -t -e "$CHANGE_MASTER_COMMON_SQL, MASTER_LOG_FILE='master-active-bin.000001', MASTER_PORT=13306;  $START_SLAVE_SQL";
    $SANDBOXES_HOME/slave-2/use -v -t -e "$CHANGE_MASTER_COMMON_SQL, MASTER_LOG_FILE='master-passive-bin.000001', MASTER_PORT=13307;  $START_SLAVE_SQL";
}

# $1 sandbox name
load_sample_databases() {
# https://launchpad.net/test-db/
    SAMPLES_DIR=$DEMOS_HOME/assets/sample-databases/
    SB=$SANDBOXES_HOME/$1/use

[ -x $SB ] || die "Can't find ./use script for sandbox $1"

# I'm assuming that if the employees_db-full file is there, the others are too
[ -f $SAMPLES_DIR/employees_db-full-1.0.6.tar.bz2 ] || {

[ -d "$SAMPLES_DIR" ] || mkdir -p $SAMPLES_DIR;
    cd $SAMPLES_DIR;

    wget -c https://launchpad.net/test-db/employees-db-1/1.0.6/+download/employees_db-full-1.0.6.tar.bz2;
    wget -c http://downloads.mysql.com/docs/world.sql.gz;
    wget -c http://downloads.mysql.com/docs/world_innodb.sql.gz;
    wget -c http://downloads.mysql.com/docs/sakila-db.tar.gz;

    tar xjvf employees_db-full-1.0.6.tar.bz2;
    gunzip world.sql.gz;
    gunzip world_innodb.sql.gz;
    tar xzvf sakila-db.tar.gz;
    
}
    # needs to be there to use employees.sql 
    cd $SAMPLES_DIR/employees_db/;
    $SB < $SAMPLES_DIR/employees_db/employees.sql;
    $SB < $SAMPLES_DIR/sakila-db/sakila-schema.sql;
    $SB < $SAMPLES_DIR/sakila-db/sakila-data.sql;
    $SB < $SAMPLES_DIR/world.sql;
    $SB < $SAMPLES_DIR/world_innodb.sql;
}