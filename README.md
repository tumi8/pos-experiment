# pos-experiment

A two-node demo: node-a sends Ethernet packets with MoonGen; node-b sends them
back. It repeats the test for eight packet sizes, about 20 seconds each, and
records throughput and optional energy measurements.

## Run

On kaunas, reserve the shared nodes, then use the development CLI for the
RO-Crate daemon:

```bash
/srv/testbed/pos/cli/venv3/bin/pos calendar create --start now --duration 60 narva klaipeda
export PATH="/home/warmuth/pos/dev/cli-dev/venv3/bin:$PATH"
cd ~/experiments/pos-experiment
pos nodes list
bash experiment.sh narva klaipeda
```

Continue only if the reservation succeeds. The development setup does not
enforce the system calendar, so reserve the nodes to avoid overlapping runs.

Choose two available, directly connected nodes. The script reserves them,
selects an image, reboots them, builds MoonGen, runs the tests and releases them.
It first releases existing allocations of both nodes, including their other nodes.

To choose a different image, add its name:

```bash
bash experiment.sh narva klaipeda debian-bookworm
```

Build tools and kernel headers must be available in the image. The hardware
run has not been verified. Use `--help` for the command syntax.

## Variables

The included port settings are for **narva / klaipeda**:

| File | Setting |
| --- | --- |
| `node-a/local-variables-a.yml` | narva PCI `0000:03:00.0`, MoonGen ID `0` |
| `node-b/local-variables-b.yml` | klaipeda PCI `0000:02:00.0`, MoonGen ID `0` |
| `global-variables.yml` | MoonGen repository/version and driver repository |
| `loop-variables.yml` | Packet sizes, one test per size |

For other nodes, change the PCI addresses in the local files; keep MoonGen ID `0`.
Setup binds only that interface to the driver and limits MoonGen to it.
Before rebooting, the script enables IOMMU passthrough for the `igb_uio` driver.
Use test ports, not management ports. No IP addresses or TCP/UDP ports are needed.

## Results

The allocation output prints a new result folder under `/srv/testbed/results/`.
Traffic logs go into `scripts/<node>/`; energy CSVs into `energy/<node>/`.
The RO-Crate daemon also records metadata linking the files to each test.
Energy measures the node's power supply; failures print warnings and the demo
continues. After an interrupted run, check for remaining processes/measurements.

To print throughput statistics after a run, replace the path below with its
result folder:

```bash
cd evaluation
bash create_venv.sh
.venv/bin/python evaluate_throughput.py /path/to/result-folder
```

Evaluation is manual. It prints RX/TX statistics per packet size; it does not
evaluate energy or latency. The local latency histogram is not uploaded.
