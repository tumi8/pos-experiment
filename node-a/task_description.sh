#!/bin/bash

IF_ID=$(pos_get_variable interface/id)
PKT_SIZE=$(pos_get_variable pkt_size --from-loop)

# wait for other node (pos_sync)
pos_sync
echo "measuring on node-a with loop variable $PKT_SIZE"

# Energy measurement is optional: some nodes do not support it.
energy_started=false
if pos_energy_start --loop --filename measurement; then
    energy_started=true
else
    echo "WARNING: energy measurement unavailable; continuing without energy data." >&2
fi

# run loadgen & perform measurement (pos_run & sleep)
pos_run loadgen --loop -- /root/MoonGen/build/MoonGen /root/MoonGen/examples/l2-load-latency.lua \
                          --dpdk-config=/root/MoonGen/dpdk-conf.lua \
                          $IF_ID $IF_ID -s $PKT_SIZE
sleep 20
pos_sync --tag finished

# Stop energy measurement before uploading the process output.
if [ "$energy_started" = true ]; then
    pos_energy_stop || echo "WARNING: could not stop energy measurement." >&2
fi

# kill loadgen (pos_kill)
pos_kill --loop loadgen

echo "...done measuring on node-a ($PKT_SIZE)"
