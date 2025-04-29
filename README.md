# SILENT: A New Lens on Statistics in Software Timing Side Channels

Details on SILENT can be found in our [paper](https://arxiv.org/pdf/2504.19821), uploaded at arXiv.

## Quick Start

```bash
# Run with default options
./SILENT.R <alpha> <input CSV> <output folder>
./Statistical_Power_SILENT.R <input CSV>
```

## Installation

### Prerequisites

SILENT requires:
- R (https://www.r-project.org/)
- The following R packages: np, robcp, Qtools

### Docker

For convenience, you can use our Docker image:

```bash
# Build the Docker images
docker build --target silent -f Dockerfile -t silent:silent .
docker build --target power  -f Dockerfile -t silent:power .

# Run with Docker (mounting current directory)
docker run -it --rm -v $(pwd):/data silent:silent <alpha> <input CSV> <output folder>
docker run -it --rm -v $(pwd):/data silent:power <input CSV>
```
