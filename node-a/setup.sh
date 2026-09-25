#!/bin/bash

MOONGEN_REPO=$(pos_get_variable moongenrepo --from-global)
MOONGEN_BRANCH=$(pos_get_variable moongenbranch --from-global)
DPDKDRIVER_REPO=$(pos_get_variable dpdkdriverrepo --from-global)

IF=$(pos_get_variable interface/pci)

# Install MoonGen
git clone $MOONGEN_REPO /root/MoonGen
cd /root/MoonGen
git checkout $MOONGEN_BRANCH
./build.sh
./setup-hugetlbfs.sh

# Install driver
git clone $DPDKDRIVER_REPO /root/dpdk-kmods
cd /root/dpdk-kmods/linux/igb_uio
make
modprobe uio
insmod igb_uio.ko

# Bind driver to the right interface
cd /root/MoonGen/libmoon/deps/dpdk/usertools
./dpdk-devbind.py -b igb_uio $IF
