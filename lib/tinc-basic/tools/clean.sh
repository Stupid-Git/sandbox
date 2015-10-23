#!/bin/bash

pid=$(pidof nodejs)
((pid)) && sudo kill $pid

pid=$(pidof tincd)
((pid)) && sudo kill $pid
sudo rm -rf /etc/tinc/sandbox /vagrant/var/{hosts,tinc1,tinc2}

