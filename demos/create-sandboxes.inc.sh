#!/bin/bash
# Authored by Marcos Albe (markus.albe@gmail.com). Minor edits by Fernando Ipar (fipar@acm.org)
# set -x
# set DEMOS_HOME to the place where the demos/ subdirectory lives in your host. As I plan to run this from that dir, I'll just set it to $PWD
export DEMOS_HOME=/usr/local/demos
# change this if you want, this is where sandboxes will be created
export SANDBOX_HOME="$DEMOS_HOME/";
export SANDBOXES_HOME="$DEMOS_HOME/sb";
# set this to the path where your MySQL version lives. A MySQL binary directory should recide under this path (i.e. /usr/local/5.5.27)
export BINARY_BASE="/usr/local"
# you shouldn't need to change anything below this comment

export LC_ALL=en_US.UTF-8
export LANGUAGE=en_US.UTF-8

export PTBIN="$DEMOS_HOME/bin/";

export VERBOSEDEMO=""

export bold=`tput smso`
export normal=`tput rmso`

export master_active="$SANDBOXES_HOME/master-active/";
export master_passive="$SANDBOXES_HOME/master-passive/";
export slave_1="$SANDBOXES_HOME/slave-1/";
export slave_2="$SANDBOXES_HOME/slave-2/";


pause_msg () {
    msg=$1
    [ -n "$2" ] && timeout="-t $2";
    read -p "${bold} $msg  (press enter to continue...) ${normal}" -N1 $timeout;
    echo ""
}

kill_mysql()
{
    echo "Killing any remaining mysqld instance"
    killall -9 mysqld mysqld_safe 2>/dev/null
    echo "Done"
}

# exit with a failure error code and a message that is printed to stderr
die() {
    echo $* >&2
    exit 1
}

# creates a demo mysql sandbox instance
# $1 = box name
# $2 = port
# $3, ... = my_clause
create_demo_box () {
    box_name=$1
    box_port=$2
    [ -z "$box_name" -o -z "$box_port" ] && die "I need at least a box name ($1) and port ($2) to continue"
    shift; shift
    extra="";
    while [ -n "$1" ]; do
        extra="$extra --my_clause=${1}"
        shift
    done

    echo ""
    echo "creating $box_name";
    echo "============================="

    make_sandbox  5.5.27 -- \
        --upper_directory="$SANDBOXES_HOME" --sandbox_directory="$box_name" --no_ver_after_name \
        --no_show --sandbox_port=$box_port --db_user=demo --db_password=demo --repl_user=demo --repl_password=demo \
        --my_clause="innodb_buffer_pool_size=128M" \
        --my_clause="innodb_log_file_size=10M" \
        --my_clause="innodb_file_per_table" \
        --my_clause="innodb_fast_shutdown=2" \
        --my_clause="innodb_flush_log_at_trx_commit=2" \
        --my_clause="log-bin=${box_name}-bin" \
        --my_clause="binlog-format=STATEMENT" \
        --my_clause="skip-slave-start" \
        --my_clause="report-host=$box_name" \
        --my_clause="report-port=$box_port" \
        --my_clause="server-id=$box_port" \
        --my_clause="max-connections=500" \
        $extra

    # --my_clause="innodb_thread_concurrency=6" \

    sudo sed --in-place=.demo.bak "s/127\.0\.0\.1/127.0.0.1 ${box_name} /g" /etc/hosts
}


# reinitializes existing sandboxes (using the backed up datadir)
reinit_instances()
{
    for i in `ls $SANDBOXES_HOME`; do
        restore_datadir $i
    done
}

start_instance ()
{
    echo "starting instance ($1)"
    [ -n "$1" ] || die "I need a sandbox name to start"
    SB=$SANDBOXES_HOME/$1
    [ -d "$SB/data" ] || die "given sandbox ($1) doesn't exists or is incomplete"
    $SB/start;
    echo "started $1"
}

stop_instance ()
{
    echo "stopping instance ($1)"
    [ -n "$1" ] || die "I need a sandbox name to stop"
    SB=$SANDBOXES_HOME/$1
    [ -d "$SB/data" ] || die "given sandbox ($1) doesn't exists or is incomplete"
    SB_PID=$(cat $SB/data/mysql_sandbox*.pid)
    [ -d /proc/$SB_PID ] && [ "`ps --format comm --no-heading --pid $SB_PID`" == "mysqld" ] && $SB/my sqladmin shutdown
    echo "stopped $1"
}

# backs up a sandbox's datadir
# $1 : sandbox we want to backup
backup_datadir()
{
    echo "creating backup..."
    [ -n "$1" ] || die "I need a sandbox name to restore"
    [ -d "$SANDBOXES_HOME/$1/data/" ] && {
        mkdir $VERBOSEDEMO -p $DEMOS_HOME/assets/loaded-datadir/$1/
        stop_instance $1
        cp $VERBOSEDEMO -r $SANDBOXES_HOME/$1/data/ $DEMOS_HOME/assets/loaded-datadir/$1;
        echo "created backup of $1 in $DEMOS_HOME/assets/loaded-datadir/$1";
    }
}

backup_generic_datadir()
{
    echo ""
    echo "creating generic backup..."
    echo "=========================="
    SB_NAME="${1:-master-active}"
    SB="${SANDBOXES_HOME}/${SB_NAME}"
    GENERIC_DATADIR=$DEMOS_HOME/assets/loaded-datadir/generic

    [ -d "$SB/data" ] || die "reference datadir ($SB/data) doesn't exists"
    [ -d "$GENERIC_DATADIR" ] && rm $VERBOSEDEMO -rf $GENERIC_DATADIR;
    echo "removed old generic datadir";

    stop_instance $SB_NAME
    cp $VERBOSEDEMO -a $SB/data/ $GENERIC_DATADIR;
    echo "created generic datadir in $GENERIC_DATADIR using $SB/data";
    start_instance $SB_NAME
}

# restore a sandbox's datadir, then starts it
# $1 : sandbox we want to restore
restore_datadir()
{
    echo "restoring datadir..."
    [ -n "$1" ] || die "I need a sandbox name to restore"
    [ -d "$SANDBOXES_HOME/$1/" ] && {
        zap_datadir $1
        cp $VERBOSEDEMO -r $DEMOS_HOME/assets/loaded-datadir/$1/data/ $SANDBOXES_HOME/$1/data/;
        echo "restored $1 with datadir from $DEMOS_HOME/assets/loaded-datadir/$1/data/";
        start_instance $1
    }
}

restore_generic_datadir ()
{
    echo "restoring generic datadir..."
    [ -n "$1" ] || die "I need a sandbox name to restore"
    GENERIC_DATADIR=$DEMOS_HOME/assets/loaded-datadir/generic/
    SB="$SANDBOXES_HOME/$1"
    [ -d "$GENERIC_DATADIR" ] || die "generic datadir ($GENERIC_DATADIR) doesn't exists"
    zap_datadir $1
    echo "copying files from $GENERIC_DATADIR to $SB/data/"
    cp $VERBOSEDEMO -a $GENERIC_DATADIR $SB/data/;
    echo "restored $1 with generic datadir ($GENERIC_DATADIR)";
    start_instance $1
}

# stops a sandbox and clears its datadir
# $1 : sandbox
zap_datadir()
{
    echo "removing datadir..."
    [ -n "$1" ] || die "I need a sandbox name to zap"
    [ -d $SANDBOXES_HOME/$1/data ] || die "nothing to remove in $SANDBOXES_HOME/$1/data"

	stop_instance $1
    rm $VERBOSEDEMO -rf $SANDBOXES_HOME/$1/data/; echo "zapped $SANDBOXES_HOME/$1/data/"
}

# reinitializes all sandboxes for replication tests
demo_recipes_boxes_reset_data_and_replication () {
    echo "resetting all sanboxes"
    if [ -d "$SANDBOXES_HOME" ];
    then {
        kill_mysql
        for i in `ls $SANDBOXES_HOME`; do {
            echo "";
            echo "restoring $i from binary backup ... "
            echo "==============================================="
            restore_generic_datadir $i
        } done;
        demo_recipes_boxes_set_replication;
    } else {
        $DEMOS_HOME/create-sandboxes.sh;
    } fi
}

# initializes slave threads on all sandboxes
demo_recipes_boxes_set_replication () {
    echo "";
    echo "setting replication...";
    echo "======================";
    STOP_SLAVE_SQL="SLAVE STOP;"
    CHANGE_MASTER_COMMON_SQL="CHANGE MASTER TO MASTER_HOST='127.0.0.1', MASTER_USER='demo', MASTER_PASSWORD='demo', MASTER_LOG_POS=107"
    START_SLAVE_SQL="SLAVE START; SELECT SLEEP(0.5); SHOW SLAVE STATUS\G"

    $SANDBOXES_HOME/master-active/use -v -t -e "$STOP_SLAVE_SQL $CHANGE_MASTER_COMMON_SQL, MASTER_LOG_FILE='master-passive-bin.000001', MASTER_PORT=13307;  $START_SLAVE_SQL SHOW MASTER STATUS; SHOW SLAVE HOSTS;";
    $SANDBOXES_HOME/master-passive/use -v -t -e "$STOP_SLAVE_SQL $CHANGE_MASTER_COMMON_SQL, MASTER_LOG_FILE='master-active-bin.000001', MASTER_PORT=13306;  $START_SLAVE_SQL SHOW MASTER STATUS; SHOW SLAVE HOSTS;";
    $SANDBOXES_HOME/slave-1/use -v -t -e "$STOP_SLAVE_SQL $CHANGE_MASTER_COMMON_SQL, MASTER_LOG_FILE='master-active-bin.000001', MASTER_PORT=13306;  $START_SLAVE_SQL";
    $SANDBOXES_HOME/slave-2/use -v -t -e "$STOP_SLAVE_SQL $CHANGE_MASTER_COMMON_SQL, MASTER_LOG_FILE='master-passive-bin.000001', MASTER_PORT=13307;  $START_SLAVE_SQL";

    pt-slave-find --defaults-file=$SANDBOXES_HOME/master-active/my.sandbox.cnf --recursion-method=hosts
}

# loads the sample databases into a sandbox
# $1 sandbox name
load_sample_databases() {
    echo ""
    echo "loading samples..."
    echo "=================="
    SAMPLES_DIR=$DEMOS_HOME/assets/sample-databases/
    SB=$SANDBOXES_HOME/$1/use

    [ -x $SB ] || die "Can't find ./use script for sandbox $1"

    # I'm assuming that if the employees_db-full file is there, the others are too
    [ -f $SAMPLES_DIR/employees_db-full-1.0.6.tar.bz2 ] || {
        [ -d "$SAMPLES_DIR" ] || mkdir $VERBOSEDEMO -p $SAMPLES_DIR;
        cd $SAMPLES_DIR;

        wget --progress=bar -c https://launchpad.net/test-db/employees-db-1/1.0.6/+download/employees_db-full-1.0.6.tar.bz2;
        wget --progress=bar -c http://downloads.mysql.com/docs/world.sql.gz;
        wget --progress=bar -c http://downloads.mysql.com/docs/world_innodb.sql.gz;
        wget --progress=bar -c http://downloads.mysql.com/docs/sakila-db.tar.gz;

        tar xjvf employees_db-full-1.0.6.tar.bz2;
        gunzip world.sql.gz;
        gunzip world_innodb.sql.gz;
        tar xzvf sakila-db.tar.gz;
    }

    # Once again, assuming that if the employees data dir is there, then the data is present.
    [ -d $SANDBOXES_HOME/$1/data/employees/ ] || {
        # needs to be there to use employees.sql
        cd $SAMPLES_DIR/employees_db/
        $SB < $SAMPLES_DIR/employees_db/employees.sql

        $SB < $SAMPLES_DIR/sakila-db/sakila-schema.sql
        $SB < $SAMPLES_DIR/sakila-db/sakila-data.sql

        $SB -e "CREATE DATABASE IF NOT EXISTS world_myisam";
        $SB world_myisam < $SAMPLES_DIR/world.sql

        $SB -e "CREATE DATABASE IF NOT EXISTS world";
        $SB world < $SAMPLES_DIR/world_innodb.sql
    }
    echo "done loading samples"
    cd -
}



poison_slaves ()
{
    set -x
    echo "Poisoning slaves"
    set +x
    $slave_2/use -v -v -v -t -e "INSERT INTO world.Country VALUES ('DYO', 'Duchy of Young', 'South America', 'South America', 40, 1837, 15797, 75.2, 20831, 19967, 'Young', 'Monarchy', 'Grand Duke Ignacio Nin', 3492, 'YO')";
    $slave_1/use -v -v -v -t -e "INSERT INTO world.City VALUES (NULL, 'Las Flores', 'URY', 'Maldonado', 200)";
    set -x
}

checksum_slaves ()
{
    set -x
    echo "Running pt-table-checksum"
    set +x
    pt-table-checksum --ignore-databases=employees --replicate=percona.checksums --create-replicate-table --empty-replicate-table --replicate-check  h=127.0.0.1,P=13306,u=demo,p=demo
    pt-table-checksum --ignore-databases=employees --replicate=percona.checksums --replicate-check --replicate-check-only h=127.0.0.1,P=13306,u=demo,p=demo
    set -x
}

enable_slow_log ()
{
    set -x
    [ -n "$1" ] || die "I need a sandbox name to configure"
    echo "enabling slow log for $1..."
    SB=$SANDBOXES_HOME/$1/use
    $SB -v -t -e "SET GLOBAL slow_query_log=1";
    $SB -v -t -e "SET GLOBAL slow_query_log_timestamp_always=1";
    $SB -v -t -e "SET GLOBAL slow_query_log_timestamp_precision=microsecond";
    $SB -v -t -e "SET GLOBAL slow_query_log_use_global_control=long_query_time,log_slow_verbosity";
    $SB -v -t -e "SET GLOBAL log_slow_slave_statements=1";
    $SB -v -t -e "SET GLOBAL log_slow_verbosity=full";
    $SB -v -t -e "SET GLOBAL long_query_time=0";
    show_slow_log_settings $1
}

disable_slow_log ()
{
    set -x
    [ -n "$1" ] || die "I need a sandbox name to configure"
    echo "disabling slow log for $1..."
    SB=$SANDBOXES_HOME/$1/use
    $SB -v -t -e "SET GLOBAL slow_query_log=0";
    $SB -v -t -e "SET GLOBAL slow_query_log_timestamp_always=0";
    $SB -v -t -e "SET GLOBAL slow_query_log_timestamp_precision=second";
    $SB -v -t -e "SET GLOBAL slow_query_log_use_global_control=all'";
    $SB -v -t -e "SET GLOBAL log_slow_slave_statements=0";
    $SB -v -t -e "SET GLOBAL log_slow_verbosity=''";
    $SB -v -t -e "SET GLOBAL long_query_time=1";
    show_slow_log_settings $1
}

show_slow_log_settings () {
    set -x
    [ -n "$1" ] || die "I need a sandbox name to configure"
    echo "slow log settings from $1..."
    SB=$SANDBOXES_HOME/$1/use
    $SB -v -t -e "SELECT @@global.slow_query_log_timestamp_always, @@global.slow_query_log_timestamp_precision, @@global.slow_query_log_use_global_control, @@global.long_query_time, @@global.log_slow_verbosity, @@global.log_slow_slave_statements\G"
}

slap_it () {
    set -x
    [ -n "$1" ] || die "I need a sandbox name to slap"
    echo "slapping $1..."
    SB=$SANDBOXES_HOME/$1
    $SB/my sqlslap \
        --verbose \
        --concurrency=24 \
        --iterations=10 \
        --create-schema=employees \
        --auto-generate-sql \
        --engine=innodb \
        --auto-generate-sql-unique-query-number=180 \
        --auto-generate-sql-execute-number=
        --auto-generate-sql-load-type=mixed \
        --auto-generate-sql-write-number=300 \
        --auto-generate-sql-write-number=300 \
        --number-of-queries=1800 &
}

sysbench_it () {
    set -x
    [ -n "$1" ] || die "I need a sandbox name to slap"
    echo "sysbench'ing $1..."
    SB=$SANDBOXES_HOME/$1
    SB_SOCKET=`grep "socket" $SB/my.sandbox.cnf |tail -n1 |awk -F"=" '{ print $2 }' |awk '{ print $1 }'`;

    # seems to give good results, commenting while testing other stuff 500QPS
    # + sysbench --test=/usr/local/demos/assets/sysbench/oltp.lua --report-interval=5 --oltp_tables_count=4 --oltp-table-size=250000 --oltp-read-only=off --oltp-range-size=8000 --oltp-index-updates=6 --oltp-dist-type=STRING --rand-init=on --rand-type=pareto --mysql-socket=/tmp/mysql_sandbox13306.sock --mysql-user=demo --mysql-password=demo --num-threads=8 --max-time=120 --max-requests=0 --percentile=99 run

    # this gives contention headaches everywhere 300QPS; awesome display for pt-query-digest
    #    SYSBENCH="sysbench --test=$DEMOS_HOME/assets/sysbench/oltp.lua  --report-interval=5 \
    #                --oltp_tables_count=4 --oltp-table-size=400000 --oltp-dist-type=special --oltp-read-only=off \
    #                 --oltp-range-size=9000 --oltp-index-updates=6 --oltp-order-ranges=3  \
    #                --rand-init=on  --rand-type=pareto \
    #                --mysql-socket=$SB_SOCKET --mysql-user=demo --mysql-password=demo \
    #                --num-threads=16 --max-time=120 --max-requests=0 --percentile=99"


    SYSBENCH="sysbench --test=$DEMOS_HOME/assets/sysbench/oltp.lua  --report-interval=5 \
                --oltp_tables_count=4 --oltp-table-size=250000 --oltp-dist-type=special --oltp-read-only=off \
                --oltp-range-size=6000 --oltp-index-updates=10 --oltp_non_index_updates=40 --oltp-order-ranges=3  --oltp-distinct-ranges=3 \
                --rand-init=on  --rand-type=pareto \
                --mysql-socket=$SB_SOCKET --mysql-user=demo --mysql-password=demo \
                --num-threads=6 --max-time=30 --max-requests=0 --percentile=99"

    $SB/use -v -t -e "DROP DATABASE IF EXISTS sbtest; CREATE DATABASE IF NOT EXISTS sbtest"
    time $SYSBENCH prepare;
    $SYSBENCH run

}

trace_it () {
    SB=${1:-"master-active"};
    strace -p `cat /usr/local/demos/sb/$SB/data/mysql_sandbox13306.pid` -f -c
}

set_flush_at_trx () {
     set -x
    [ -n "$1" ] || die "I need a sandbox name to config"
    SB=$SANDBOXES_HOME/$1
    $SB/use -v -t -e "SET GLOBAL innodb_flush_log_at_trx_commit=$2;";

}

rotate_slow_log () {
     set -x
    [ -n "$1" ] || die "I need a sandbox name to rotate it's slow log"
    ORIGINAL=$(get_slow_log_filename "$1")
    MOVED=/tmp/$1-slow-log.`date +%s`
    cp -v  $ORIGINAL $MOVED;
    rm -v -f $ORIGINAL
    $SB/use -v -t -e "FLUSH LOGS"
}

get_slow_log_filename () {
    $SANDBOXES_HOME/$1/use -B -N -e "SELECT @@global.slow_query_log_file";
    # $SANDBOXES_HOME/$1/data/lucid64-slow.log
}