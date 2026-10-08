#!/bin/bash

set -e

MOONGEN_REPO=$(pos_get_variable moongenrepo --from-global)
MOONGEN_BRANCH=$(pos_get_variable moongenbranch --from-global)
DPDKDRIVER_REPO=$(pos_get_variable dpdkdriverrepo --from-global)

IF=$(pos_get_variable interface/pci)

# Install MoonGen
git clone $MOONGEN_REPO /root/MoonGen
cd /root/MoonGen
git checkout $MOONGEN_BRANCH
./build.sh --noBind
./setup-hugetlbfs.sh

# Install driver
git clone $DPDKDRIVER_REPO /root/dpdk-kmods
cd /root/dpdk-kmods/linux/igb_uio
make
modprobe uio
[ -d /sys/module/igb_uio ] || insmod igb_uio.ko

# Bind driver to the right interface
cd /root/MoonGen/libmoon/deps/dpdk/usertools
# Only the configured test interface may be disconnected from the kernel.
./dpdk-devbind.py --force -b igb_uio "$IF"
# dpdk-devbind can report a binding failure without returning an error.
[ -e "/sys/bus/pci/drivers/igb_uio/$IF" ]

# Expose only this interface to MoonGen, so it always has port ID 0.
echo "DPDKConfig { pciWhitelist = {\"$IF\"} }" > /root/MoonGen/dpdk-conf.lua
