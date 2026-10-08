#!/bin/bash

IF_ID=$(pos_get_variable interface/id)
PKT_SIZE=$(pos_get_variable pkt_size --from-loop)

pos_sync
echo "measuring on node-b with loop variable $PKT_SIZE"

# Energy measurement is optional: some nodes do not support it.
energy_started=false
if pos_energy_start --loop --filename measurement; then
    energy_started=true
else
    echo "WARNING: energy measurement unavailable; continuing without energy data." >&2
fi

pos_run reflector --loop -- /root/MoonGen/build/MoonGen /root/MoonGen/libmoon/examples/reflector.lua \
                            --dpdk-config=/root/MoonGen/dpdk-conf.lua $IF_ID
# Wait until node-a has finished measuring.
pos_sync --tag finished
# Stop energy measurement before uploading the process output.
if [ "$energy_started" = true ]; then
    pos_energy_stop || echo "WARNING: could not stop energy measurement." >&2
fi

pos_kill --loop reflector

echo "...done measuring on node-b ($PKT_SIZE)"
