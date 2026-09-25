#!/bin/bash

# Experiment demonstrating global, local, and loop variables

set -x
set -e

#TODO define instance to use for experiment
INSTANCE=''

NODE_A="$INSTANCE-a"
NODE_B="$INSTANCE-b"

# free allocation to be sure
pos allocations free -k $NODE_A

# allocate experiment nodes
pos allocations allocate $NODE_A $NODE_B

# load global variables (the allocation is referred to by any node within it)
pos allocations set_variables $NODE_A --as-global ./global-variables.yml

# load local variables
pos allocations set_variables $NODE_A ./node-a/local-variables-a.yml
pos allocations set_variables $NODE_B ./node-b/local-variables-b.yml

# load loop variables
pos allocations set_variables $NODE_A --as-loop ./loop-variables.yml

# configure nodes
pos nodes image $NODE_A debian-trixie
pos nodes image $NODE_B debian-trixie

# reset/reboot nodes
{ pos nodes reset $NODE_A; echo "$NODE_A rebooted."; } &
{ pos nodes reset $NODE_B; echo "$NODE_A rebooted."; } &
wait

# setup nodes
pos commands launch --infile node-a/setup.sh --queued $NODE_A
pos commands launch --infile node-b/setup.sh --queued $NODE_B

# execute experiment on nodes
pos commands launch --infile node-a/task_description.sh --queued --loop $NODE_A
# as all nodes sync at start and end of measurement scripts, launching the
# loop for the last node in blocking mode accurately displays the current
# progress
pos commands launch --infile node-b/task_description.sh --blocking --loop $NODE_B

# free nodes
pos allocations free -k $NODE_A
