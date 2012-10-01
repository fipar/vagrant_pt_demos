#!/bin/bash
# provisioner for the percona-toolkit-demos Vagrant box
# Fernando Ipar - fipar@acm.org

# set up Percona repo and install percona-toolkit

gpg --list-keys|grep mysql-dev@percona.com >/dev/null || {
    gpg --keyserver  hkp://keys.gnupg.net --recv-keys 1C4CBDCDCD2EFD2A
    gpg -a --export CD2EFD2A | apt-key add -
}

grep 'repo.percona.com' /etc/apt/sources.list >/dev/null || {
    cat << EOF >> /etc/apt/sources.list

deb http://repo.percona.com/apt lucid main
deb-src http://repo.percona.com/apt lucid main

EOF

    apt-get update

}

/etc/init.d/vboxadd setup

# /vagrant is where you cloned the git project (/home/you/vagrant_pt_demos/ for example)
export usb=/vagrant/usb/;
apt_no_download=""
test -d "$usb" && {
    echo "quick provisioning available!"!
    cp -v $usb/debs/*.deb /var/cache/apt/archives/
    cp -v $usb/mysql-sandbox.tar.gz /tmp
    cp -v $usb/percona-server.tar.gz /tmp
    tar xzvf $usb/sysbench.tar.gz -C /tmp
    apt_no_download="--no-download"
}

apt-get -y --force-yes ${apt_no_download} install git-core bzr sysstat build-essential autoconf automake libtool libaio1 percona-toolkit perl-doc libmysqlclient18-dev
# install mysql-sandbox and percona-server-5.5 binary

sleep 3

rm -vrf /usr/local/mysql-sandbox/
rm -vrf /usr/local/demos/

test -d /usr/local/mysql-sandbox/ || {
    wget -c --progress=bar:force https://launchpad.net/mysql-sandbox/mysql-sandbox-3/mysql-sandbox-3/+download/MySQL-Sandbox-3.0.25.tar.gz -O /tmp/mysql-sandbox.tar.gz
    tar xzf /tmp/mysql-sandbox.tar.gz -C /usr/local/ --transform "s/MySQL-Sandbox-3.0.25/mysql-sandbox/g"
    pushd /usr/local/mysql-sandbox/
    perl Makefile.PL PREFIX=/usr/local/mysql-sandbox
    make
    make test
    make install
    echo 'export PATH=$PATH:/usr/local/mysql-sandbox/bin'>>/etc/bash.bashrc
    echo 'export PERL5LIB=$PERL5LIB:/usr/local/mysql-sandbox/lib/'>>/etc/bash.bashrc
    echo 'export SANDBOXES_HOME=/usr/local/demos/sb'>>/etc/bash.bashrc
    echo 'export SANDBOX_HOME=/usr/local/demos/'>>/etc/bash.bashrc
    rm -f /tmp/mysql-sandbox.tar.gz
    popd
}

test -d /usr/local/5.5.27/ || {
    wget -c --progress=bar:force http://www.percona.com/redir/downloads/Percona-Server-5.5/Percona-Server-5.5.27-28.1/binary/linux/x86_64/Percona-Server-5.5.27-rel28.1-296.Linux.x86_64.tar.gz -O /tmp/percona-server.tar.gz
    tar xzf /tmp/percona-server.tar.gz -C /usr/local --transform "s/Percona-Server-5.5.27-rel28.1-296.Linux.x86_64/5.5.27/g"
    echo 'export PATH=$PATH:/usr/local/5.5.27/bin'>>/etc/bash.bashrc
    rm -f /tmp/percona-server.tar.gz
}

test -d /tmp/sysbench || {
    cd /tmp
    pushd /tmp
    bzr branch lp:sysbench

    cd /tmp/sysbench
    pushd /tmp/sysbench
    ./autogen.sh
    ./configure && make
}
cd /tmp/sysbench
make install

test -d /usr/local/demos/ || {
    pushd /tmp/
    git clone https://github.com/markusalbe/vagrant_pt_demos
    cp -rv vagrant_pt_demos/demos /usr/local
    chown -v -R vagrant.vagrant /usr/local/demos/
    echo 'export PATH=$PATH:/usr/local/demos/'>>/etc/bash.bashrc
    rm -rf /tmp/vagrant_pt_demos
    popd

    # wget -c http://ufpr.dl.sourceforge.net/project/sysbench/sysbench/0.4.12/sysbench-0.4.12.tar.gz -O /tmp/sysbench-0.4.12.tar.gz
    # sudo tar xzvf /tmp/sysbench-0.4.12.tar.gz -C /tmp --transform "s/sysbench-0.4.12/sysbench/g"
    # sed --in-place=.bak "s/AC_PROG_LIBTOOL/\#AC_PROG_LIBTOOL\nAC_PROG_RANLIB/g" configure.ac

    test -d /usr/local/demos/output || mkdir /usr/local/demos/output

    mkdir -p /usr/local/demos/assets/
    test -d $usb/sample-databases && {
        cp -a $usb/sample-databases /usr/local/demos/assets/
    }

    mkdir /usr/local/demos/assets/sysbench
    if [ -d $usb/sysbench-tests/ ];
    then {
        cp -v $usb/sysbench-tests/* /usr/local/demos/assets/sysbench
    } else {
        cd /usr/local/demos/assets/sysbench
        pushd /usr/local/demos/assets/sysbench
        wget -c --progress=bar:force http://bazaar.launchpad.net/~percona-dev/percona-benchmark-result/sysbench.oltp.intel520/download/vadim%40percona.com-20120511183144-dksld1z0qqzmgcwu/oltp.lua-20120511183137-pyv3pzq9ubh0o3ee-212/oltp.lua
        wget -c --progress=bar:force http://bazaar.launchpad.net/~percona-dev/percona-benchmark-result/sysbench.oltp.intel520/download/vadim%40percona.com-20120511183144-dksld1z0qqzmgcwu/common.lua-20120511183137-pyv3pzq9ubh0o3ee-208/common.lua
        wget -c --progress=bar:force http://bazaar.launchpad.net/~percona-dev/percona-benchmark-result/sysbench.oltp.intel520/download/vadim%40percona.com-20120511183144-dksld1z0qqzmgcwu/delete.lua-20120511183137-pyv3pzq9ubh0o3ee-209/delete.lua
        wget -c --progress=bar:force http://bazaar.launchpad.net/~percona-dev/percona-benchmark-result/sysbench.oltp.intel520/download/vadim%40percona.com-20120511183144-dksld1z0qqzmgcwu/insert.lua-20120511183137-pyv3pzq9ubh0o3ee-210/insert.lua
        wget -c --progress=bar:force http://bazaar.launchpad.net/~percona-dev/percona-benchmark-result/sysbench.oltp.intel520/download/vadim%40percona.com-20120511183144-dksld1z0qqzmgcwu/oltp_simple.lua-20120511183137-pyv3pzq9ubh0o3ee-213/oltp_simple.lua
        wget -c --progress=bar:force http://bazaar.launchpad.net/~percona-dev/percona-benchmark-result/sysbench.oltp.intel520/download/vadim%40percona.com-20120511183144-dksld1z0qqzmgcwu/parallel_prepare.lua-20120511183137-pyv3pzq9ubh0o3ee-214/parallel_prepare.lua
        wget -c --progress=bar:force http://bazaar.launchpad.net/~percona-dev/percona-benchmark-result/sysbench.oltp.intel520/download/vadim%40percona.com-20120511183144-dksld1z0qqzmgcwu/select.lua-20120511183137-pyv3pzq9ubh0o3ee-215/select.lua
        wget -c --progress=bar:force http://bazaar.launchpad.net/~percona-dev/percona-benchmark-result/sysbench.oltp.intel520/download/vadim%40percona.com-20120511183144-dksld1z0qqzmgcwu/select_random_points-20120511183137-pyv3pzq9ubh0o3ee-216/select_random_points.lua
        wget -c --progress=bar:force http://bazaar.launchpad.net/~percona-dev/percona-benchmark-result/sysbench.oltp.intel520/download/vadim%40percona.com-20120511183144-dksld1z0qqzmgcwu/select_random_ranges-20120511183137-pyv3pzq9ubh0o3ee-217/select_random_ranges.lua
        wget -c --progress=bar:force http://bazaar.launchpad.net/~percona-dev/percona-benchmark-result/sysbench.oltp.intel520/download/vadim%40percona.com-20120511183144-dksld1z0qqzmgcwu/update_index.lua-20120511183137-pyv3pzq9ubh0o3ee-219/update_index.lua
        wget -c --progress=bar:force http://bazaar.launchpad.net/~percona-dev/percona-benchmark-result/sysbench.oltp.intel520/download/vadim%40percona.com-20120511183144-dksld1z0qqzmgcwu/update_non_index.lua-20120511183137-pyv3pzq9ubh0o3ee-220/update_non_index.lua
    } fi
    chown --recursive vagrant.vagrant /usr/local/demos/
}


cd /vagrant/demos/;
# mkdir /usr/local/demos/_from-git/;
for i in `ls *.sh`; do {
    # mv -v /usr/local/demos/$i /usr/local/demos/_from-git/;
    [ -f /usr/local/demos/$i ] && rm -v /usr/local/demos/$i
    ln -v -s /vagrant/demos/$i /usr/local/demos/;
    chmod +x /usr/local/demos/$i
} done;

cd /usr/local/demos

# we need these here, or run /etc/bash.bashrc, since that is not run before the line below
# export PATH=$PATH:/usr/local/percona-server/bin:/usr/local/mysql-sandbox/bin:/usr/local/demos/:/usr/local/mysql-sandbox/
# export PERL5LIB=$PERL5LIB:/usr/local/mysql-sandbox/lib/
# export SANDBOXES_HOME=/usr/local/demos/sb
# export SANDBOX_HOME=/usr/local/demos/
# if at least one sandbox exists, I assume all of them do
# [ -d /usr/local/demos/sb/master-active/ ] || su --preserve-environment --login - vagrant -c "/usr/local/demos/create-sandboxes.sh"
cp -vf /etc/skel/.bashrc /home/vagrant/
chown vagrant.vagrant /home/vagrant/.bashrc
echo '. /usr/local/demos/create-sandboxes.inc.sh' >> /home/vagrant/.bashrc
echo '. /usr/local/demos/create-sandboxes.sh' >> /home/vagrant/.bashrc

echo "0" > /proc/sys/vm/swappiness