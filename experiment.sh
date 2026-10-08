#!/bin/bash

# Experiment demonstrating global, local, and loop variables

set -x
set -e

if [ "${1-}" = "--help" ] || [ "${1-}" = "-h" ]; then
    echo "Usage: $0 NODE_A NODE_B [IMAGE] (default image: debian-trixie)"
    exit 0
fi
if [ "$#" -lt 2 ] || [ "$#" -gt 3 ]; then
    echo "Usage: $0 NODE_A NODE_B [IMAGE]" >&2
    exit 2
fi
NODE_A="$1"
NODE_B="$2"
IMAGE="${3:-debian-trixie}"
if [ "$NODE_A" = "$NODE_B" ]; then
    echo "Choose two different nodes." >&2
    exit 2
fi
cd "$(dirname "$0")"

# free allocation to be sure
# pos allocations free -k $NODE_A
pos allocations free $NODE_A
pos allocations free $NODE_B

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
pos nodes image $NODE_A "$IMAGE"
pos nodes image $NODE_B "$IMAGE"

# igb_uio needs IOMMU passthrough for packet transmission.
pos nodes bootparameter $NODE_A intel_iommu=on iommu=pt
pos nodes bootparameter $NODE_B intel_iommu=on iommu=pt

# reset/reboot nodes
pos nodes reset $NODE_A
pos nodes reset $NODE_B

# setup nodes
setup_a=$(pos commands launch --name setup-loadgen --infile node-a/setup.sh --queued $NODE_A)
setup_b=$(pos commands launch --name setup-reflector --infile node-b/setup.sh --queued $NODE_B)
pos commands await "$setup_a"
pos commands await "$setup_b"

# execute experiment on nodes
pos commands launch --name measurement-loadgen --infile node-a/task_description.sh --blocking --loop $NODE_A &
measurement_a=$!
status=0
# --queued disables --blocking; wait for both nodes before freeing them.
pos commands launch --name measurement-reflector --infile node-b/task_description.sh --blocking --loop $NODE_B || status=1
wait "$measurement_a" || status=1

# free nodes
# pos allocations free -k $NODE_A
pos allocations free $NODE_A
exit "$status"
