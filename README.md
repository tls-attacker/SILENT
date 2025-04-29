# SILENT: A New Lens on Statistics in Software Timing Side Channels

Details on SILENT can be found in our [paper](https://arxiv.org/pdf/2504.19821), uploaded at arXiv.

## Quick Start

```bash
# Run SILENT
./scripts/SILENT.R <alpha> <input CSV> <output folder>

# Run the Statistical Power Analysis
./scripts/Statistical_Power_SILENT.R <input CSV>
```

## Installation

Before using SILENT, ensure the following prerequisites are installed:

- R Project
- R Packages: cli, glue, jsonlite, np, robcp, Qtools

To install R, follow the instructions for your operating system on the [R Project website](https://www.r-project.org/). Once installed, open an R session and run the following command to install the required packages:

```R
install.packages(c("cli", "glue", "jsonlite", "np", "robcp", "Qtools"))
```

Once the prerequisites are installed, you are ready to use SILENT.

## Docker

For convenience, you can use our pre-configured Docker images to run SILENT without manually setting up dependencies.

Run the following commands to build the Docker images:

```bash
# Build SILENT
docker build --target silent -f Dockerfile -t silent:silent .

# Build the Statistical Power Analysis
docker build --target power -f Dockerfile -t silent:power .
```

Once the images are built, you can run SILENT using Docker. Make sure to mount the current directory to access your input and output files:

```bash
# Run SILENT
docker run -it --rm -v $(pwd):/data silent:silent <alpha> <input CSV> <output folder>

# Run the Statistical Power Analysis
docker run -it --rm -v $(pwd):/data silent:power <input CSV>
```

## Input

SILENT supports multiple input formats and automatically detects the separator (comma or semicolon). Below are the supported formats:

**Classic Format**

A CSV file containing two columns. The first column includes labels, such as 'X' and 'Y', while the second column contains the corresponding measurements.

Example: Comma Separator

```
V1,V2
X,481100
Y,531296
...
```

Example: Semicolon Separator

```
V1;V2
X;494602
Y;539770
...
```

**Column Format**

A CSV file where each column represents a different measurement series.

Example: Comma Separator

```
Series1,Series2
494602,531296
481100,539770
...
```

Example: Semicolon Separator

```
Series1;Series2
494602;531296
481100;539770
...
```

## Ouput

SILENT outputs the results directly to the console and saves them as a JSON file for further analysis. The statistical power analysis tool also prints the results to the console.
