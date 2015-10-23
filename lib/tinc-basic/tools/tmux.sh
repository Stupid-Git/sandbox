#!/bin/bash
name=tinc-basic

if [[ -z $TMUX ]]; then
  tmux -2 new -ds $name
  tmux split-window -h -t $name:1 -l 80 less +F ./var/tinc1/sandbox/logs/tinc.log
  tmux split-window -v -t $name:1.2 less +F ./var/tinc2/sandbox/logs/tinc.log
  tmux select-pane -t $name:1.1
  tmux send-keys -t $name:1.1 "# Press enter to begin..." C-m
  tmux send-keys -t $name:1.1 "./tools/tmux.sh"
  tmux attach -t $name
else
  tmux send-keys -t $name:1.1 "# The two windows on the right contain the logs for tinc1 and tinc2" C-m
  sleep 4
  tmux send-keys -t $name:1.1 "# Let's have tinc1 make an HTTP request to tinc2 through the VPN" C-m
  sleep 4
  tmux send-keys -t $name:1.1 "vagrant ssh -c 'curl 10.0.0.2:8080/from/tinc1' tinc1" C-m
  sleep 4
  tmux send-keys -t $name:1.1 "" C-m
  tmux send-keys -t $name:1.1 "# nice, now let's go the other way" C-m
  tmux send-keys -t $name:1.1 "vagrant ssh -c 'curl 10.0.0.1:8080/from/tinc2' tinc2" C-m
fi
