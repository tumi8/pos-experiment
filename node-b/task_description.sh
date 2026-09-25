#!/bin/bash

IF_ID=$(pos_get_variable interface/id)

pos_sync
echo "measuring on node-b with loop variable $PKT_SIZE"

pos_run reflector --loop -- /root/MoonGen/build/MoonGen /root/MoonGen/libmoon/examples/reflector.lua $IF_ID
sleep 20
pos_kill --loop reflector

echo "...done measuring on node-b ($PKT_SIZE)"
