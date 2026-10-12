#!/bin/bash

# Experiment demonstrating global, local, and loop variables

set -x
set -e

usage() {
    echo "Usage: $0 NODE_A NODE_B [IMAGE] [--add-metadata] [--publish]"
    echo "Default image: debian-trixie"
    echo "  --add-metadata  Run add_metadata.sh after successful evaluation."
    echo "  --publish       Run publish.sh to upload a Zenodo draft."
}

ADD_METADATA=false
PUBLISH=false
args=()
while [ "$#" -gt 0 ]; do
    case "$1" in
        --add-metadata) ADD_METADATA=true ;;
        --publish) PUBLISH=true ;;
        --help|-h) usage; exit 0 ;;
        --) shift; args+=("$@"); break ;;
        -*) echo "Unknown option: $1" >&2; usage >&2; exit 2 ;;
        *) args+=("$1") ;;
    esac
    shift
done
set -- "${args[@]}"
if [ "$#" -lt 2 ] || [ "$#" -gt 3 ]; then
    usage >&2
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
allocation_output=$(pos allocations allocate "$NODE_A" "$NODE_B")
# Release this allocation on exit, preserving any earlier failure.
trap '
    status=$?
    if ! pos allocations free "$NODE_A"; then
        echo "Failed to free nodes." >&2
        [ "$status" -ne 0 ] || status=1
    fi
    exit "$status"
' EXIT
trap 'exit 130' INT
trap 'exit 143' TERM
printf '%s\n' "$allocation_output"
RESULT_FOLDER=$(printf '%s\n' "$allocation_output" | sed -n 's/^Results in //p')
if [ -z "$RESULT_FOLDER" ]; then
    echo "Could not read the result folder from allocation output." >&2
    exit 1
fi

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
if [ "$status" -ne 0 ]; then
    echo "Measurement failed; skipping evaluation." >&2
    exit 1
fi

# copy evaluation files
pos nodes copy --blocking --recursive --name evaluation-script "$NODE_A" ./evaluation --dest /root/evaluator

# copy the current allocation's results
pos nodes copy --blocking --recursive --relative --name evaluation-results "$NODE_A" . --dest /root/experiment-results

# run evaluation
pos commands launch --name evaluation --infile evaluation/evaluation.sh --blocking "$NODE_A"

# Release the nodes before modifying or uploading the completed results.
pos allocations free "$NODE_A"
trap - EXIT

if [ "$ADD_METADATA" = true ]; then
    bash add_metadata.sh "$RESULT_FOLDER"
fi
if [ "$PUBLISH" = true ]; then
    bash publish.sh "$RESULT_FOLDER"
fi
