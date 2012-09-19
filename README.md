vagrant_pt_demos
================

Vagrant box for running percona toolkit demos


Requirements
===


This requires Oracle Virtualbox (http://www.virtualbox.org/) and
Vagrant (http://http://www.vagrantup.com/). 

Usage
===


Use should be as simple as: 

    cd <dir-where-you-cloned-the-repo>
    vagrant up

You can then run 'vagrant ssh' which will connect you to the box. 

There's a basic provisioning script that installs all the needed
software and sets up the boxes. 

Once the vm is booted and you've logged in, you'll find all the
Percona Toolkit tools in the PATH. If at any point you need to reset
the sandboxes to their initial state (sample databases loaded and
replication set up), just run: 

    demo_recipes_boxes_reset_data_and_replication



