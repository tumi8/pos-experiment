#!/bin/bash

set -e

# Install virtual environment support on the Debian experiment node.
export DEBIAN_FRONTEND=noninteractive
apt-get update
apt-get install -y python3-venv

cd /root/evaluator
# Recreate the environment because a copied .venv is not portable.
rm -rf .venv
bash create_venv.sh

mkdir -p /root/evaluation
.venv/bin/python evaluate_throughput.py /root/experiment-results > /root/evaluation/throughput.txt

# upload results
pos_upload --recursive /root/evaluation --outfile evaluation
