# pos-experiment

A two-node MoonGen demo measuring throughput and optional energy use across
eight packet sizes. One node sends Ethernet packets; the other reflects them.

## Run

Reserve the nodes, then run:

```bash
bash experiment.sh <node-a> <node-b> --add-metadata --publish
```

Both flags also work separately. `--publish` requires a Zenodo token at
`~/.secrets/zenodo_token`. Use `bash experiment.sh --help` for syntax.

## Configuration

The included settings are for directly connected **narva / klaipeda**:

| File | Setting |
| --- | --- |
| `node-a/local-variables-a.yml` | node-a PCI `0000:03:00.0`, MoonGen ID `0` |
| `node-b/local-variables-b.yml` | node-b PCI `0000:02:00.0`, MoonGen ID `0` |
| `global-variables.yml` | MoonGen repository/version and driver repository |
| `loop-variables.yml` | Packet sizes, one test per size |

For other nodes, update the PCI addresses in the local files and keep MoonGen
ID `0`. Use test interfaces, not management interfaces. The image needs build
tools and kernel headers.

## Results

The allocation output prints the result folder under `/srv/testbed/results/`:

- Traffic logs: `scripts/<node>/`
- Optional energy CSVs: `energy/<node>/`
- Throughput report: `files/<node-a>/evaluation/throughput.txt`
- Experiment metadata: `ro-crate-metadata.json`

Energy failures produce warnings and the demo continues. After an interrupted
run, check for remaining processes and measurements.

To add metadata and upload a draft after a completed run, use the development
CLI on kaunas and replace the path below with the printed result folder:

```bash
bash add_metadata.sh /path/to/result-folder
pos results validate --result-folder /path/to/result-folder
bash publish.sh /path/to/result-folder
```

`add_metadata.sh` adds demo authors, license, title and keywords. Review its
defaults before use and run it only once per result folder. Skip it if already
run via `--add-metadata`. `publish.sh` uses the token above and prints a draft
link for review and publication on Zenodo.
