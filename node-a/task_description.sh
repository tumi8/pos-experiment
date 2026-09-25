#!/bin/bash

IF_ID=$(pos_get_variable interface/id)
PKT_SIZE=$(pos_get_variable pkt_size --from-loop)

# wait for other node (pos_sync)
#TODO
echo "measuring on node-a with loop variable $PKT_SIZE"

# run loadgen & perform measurement (pos_run & sleep)
#TODO

# kill loadgen (pos_kill)
#TODO

echo "...done measuring on node-a ($PKT_SIZE)"
