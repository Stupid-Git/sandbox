#!/bin/bash
name=tinc-basic

if [[ -z $TMUX ]]; then
  echo "Creating session..."
  tmux -2 new -ds $name
  tmux split-window -h -t $name:1 -l 80 less +F ./var/tinc1/sandbox/logs/tinc.log
  tmux split-window -v -t $name:1.2 less +F ./var/tinc2/sandbox/logs/tinc.log
  tmux split-window -v -t $name:1.1 vagrant ssh tinc2
  tmux select-pane -t $name:1.1
  tmux send-keys -t $name:1.1 "vagrant ssh tinc1" C-m
  echo "Logging in to hosts..."
  sleep 2
  tmux send-keys -t $name:1.1 "clear" C-m
  tmux send-keys -t $name:1.4 "clear" C-m
  sleep 1
  tmux send-keys -t $name:1.1 "curl tinc2:8080/hello/from/tinc1" C-m
  tmux send-keys -t $name:1.4 "curl tinc1:8080/hello/from/tinc2" C-m
  tmux attach -t $name
else
  echo "Can't nest TMUX session"
fi
