# SILENT: A New Lens on Statistics in Software Timing Side Channels

Details on SILENT can be found in our [paper](https://arxiv.org/pdf/2504.19821), uploaded at arXiv.

## Quick Start

```bash
# Run SILENT
./scripts/SILENT.R <alpha> <input CSV> <output folder> <B> <Delta>

# Run the Statistical Power Analysis
./scripts/Statistical_Power_SILENT.R <input CSV> <mu> <Delta> <p> <alpha>
```

## Parameters

### `SILENT.R`

- **`alpha`**: False positive rate (recommended: `0.1`).  
  Note: The actual false positive rate will be much lower (decaying exponentially fast in the sample size). See the paper for details.

- **`B`**: Number of bootstrap samples (recommended: `1000`).  
  For smaller `alpha` (e.g., `0.01`), increase `B` accordingly (e.g., use `10000`).

- **`Delta`**: Minimum detectable effect size. (recommended: not too small) 
  Represents the smallest side-channel difference you consider practically relevant.  
  Choose a value that is not too small; obviously depends on the application.

### `Statistical_Power_SILENT.R`

- **`mu`**: Expected side-channel size (e.g., `0.02`).  
  Should be chosen conservatively—avoid overestimating the leakage.

- **`Delta`**: Minimum detectable effect size (same as above).  
  Used to define the detection threshold.

- **`p`**: Desired detection rate (recommended: `≥ 0.9`).  
  The probability of detecting a real leakage of size `mu` or larger (true positive rate).  
  Increase this value if stronger guarantees are required.

- **`alpha`**: False positive rate (same as in `SILENT.R`).


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
docker run -it --rm -v $(pwd):/data silent:silent <alpha> <input CSV> <output folder> <B> <Delta>

# Run the Statistical Power Analysis
docker run -it --rm -v $(pwd):/data silent:power <input CSV> <mu> <Delta> <p> <alpha>
```

## Input

SILENT supports a single input format and automatically detects the separator (comma). Below is the supported format:

```csv
V1,V2
X,481100
Y,531296
...
```

A CSV file containing two columns. The first column includes labels, such as 'X' and 'Y', while the second column contains the corresponding measurements

## Ouput

SILENT outputs the results directly to the console and saves them as a JSON file for further analysis. The statistical power analysis tool also prints the results to the console.
