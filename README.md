# SILENT: A New Lens on Statistics in Software Timing Side Channels

Details on SILENT can be found in our [paper](https://arxiv.org/pdf/2504.19821), uploaded at arXiv.

## Quick Start

```bash
TODO
```

## Installation

### Prerequisites

SILENT requires:
- R (https://www.r-project.org/)
- The following R packages: TODO

### Docker

For convenience, you can use our Docker image:

```bash
# Build the Docker images
docker build --target silent -f Dockerfile -t silent:silent .
docker build --target power  -f Dockerfile -t silent:power .

# Run with Docker (mounting current directory)
docker run --rm -v $(pwd):/data silent:silent --file /data/your_data.csv
docker run --rm -v $(pwd):/data silent:power --file /data/your_data.csv
```
