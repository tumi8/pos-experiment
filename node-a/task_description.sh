#!/bin/bash

IF_ID=$(pos_get_variable interface/id)
PKT_SIZE=$(pos_get_variable pkt_size --from-loop)

# wait for other node (pos_sync)
pos_sync
echo "measuring on node-a with loop variable $PKT_SIZE"

# run loadgen & perform measurement (pos_run & sleep)
pos_run loadgen --loop -- /root/MoonGen/build/MoonGen /root/MoonGen/examples/l2-load-latency.lua \
                          $IF_ID $IF_ID -s $PKT_SIZE
sleep 20

# kill loadgen (pos_kill)
pos_kill --loop loadgen

echo "...done measuring on node-a ($PKT_SIZE)"
