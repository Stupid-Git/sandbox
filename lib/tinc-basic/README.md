# Tinc Basic
This directory contains a simple 2 node VPN setup using Vagrant and Tinc.

Run `./setup` to create the two nodes and provision them with a Nodejs web
server and Tinc + configurations.

Once complete, run `./test`, which will create a new Tmux session with 2 panes;
2 monitoring the Tinc log files and a main pane to run commands. An example
script is prepared for you once you attach, so simply hit enter to run.

All the Tinc configuration files for both nodes can be found in the `./var`
directory. 

