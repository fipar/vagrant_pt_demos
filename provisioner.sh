#!/bin/bash
# provisioner for the percona-toolkit-demos Vagrant box

# set up Percona repo and install percona-toolkit

gpg --list-keys|grep mysql-dev@percona.com >/dev/null || {
    gpg --keyserver  hkp://keys.gnupg.net --recv-keys 1C4CBDCDCD2EFD2A
    gpg -a --export CD2EFD2A | apt-key add -
}

grep 'repo.percona.com' /etc/apt/sources.list >/dev/null || {
    cat <<EOF>> /etc/apt/sources.list

deb http://repo.percona.com/apt lucid main
deb-src http://repo.percona.com/apt lucid main

EOF

apt-get update

}

apt-get -y install percona-toolkit git-core libaio1

# install mysql-sandbox and percona-server-5.5 binary

test -d /usr/local/mysql-sandbox/ || {
    wget https://launchpad.net/mysql-sandbox/mysql-sandbox-3/mysql-sandbox-3/+download/MySQL-Sandbox-3.0.25.tar.gz -O /tmp/mysql-sandbox.tar.gz --progress=bar
    tar xzvf /tmp/mysql-sandbox.tar.gz -C /usr/local/ --transform "s/MySQL-Sandbox-3.0.25/mysql-sandbox/g"
    pushd /usr/local/mysql-sandbox/ 
    perl Makefile.PL
    make
    make test
    make install
    echo "export PATH=$PATH:/usr/local/mysql-sandbox/bin">>/etc/bash.bashrc
    rm -f /tmp/mysql-sandbox.tar.gz
    popd
}

test -d /usr/local/5.5.27/ || {
    wget http://www.percona.com/redir/downloads/Percona-Server-5.5/Percona-Server-5.5.27-28.1/binary/linux/x86_64/Percona-Server-5.5.27-rel28.1-296.Linux.x86_64.tar.gz -O /tmp/percona-server.tar.gz  --progress=bar
    tar xzvf /tmp/percona-server.tar.gz -C /usr/local --transform "s/Percona-Server-5.5.27-rel28.1-296.Linux.x86_64/5.5.27/g"
    echo "export PATH=$PATH:/usr/local/percona-server/bin">>/etc/bash.bashrc
    rm -f /tmp/percona-server.tar.gz
}

test -d /usr/local/demos/ || {
    pushd /tmp/
    git clone https://github.com/fipar/vagrant_pt_demos
    cp -rv vagrant_pt_demos/demos /usr/local 
    chown -R vagrant.vagrant /usr/local/demos/
    echo "export PATH=$PATH:/usr/local/demos/">>/etc/bash.bashrc
    rm -rf /tmp/vagrant_pt_demos
    popd
}

