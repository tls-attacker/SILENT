suppressMessages(library(np))
suppressMessages(library(robcp))
suppressMessages(library(Qtools))

# Load external functions
get_script_dir <- function() {
  args <- commandArgs(trailingOnly = FALSE)
  file_arg <- "--file="
  path_idx <- grep(file_arg, args)
  
  if (length(path_idx) > 0) {
    script_path <- normalizePath(sub(file_arg, "", args[path_idx]))
    return(dirname(script_path))
  }
  
  if (!is.null(sys.frames()[[1]]$ofile)) {
    return(dirname(normalizePath(sys.frames()[[1]]$ofile)))
  }
  
  stop("Unable to determine script directory (are you running interactively?)")
}

script_dir <- get_script_dir()
source(file.path(script_dir, "functions.R"))

# ---- Parse Command-Line Arguments ----
args <- commandArgs(trailingOnly = TRUE)

if (length(args) < 3) {
  stop("Script requires at least 3 arguments: 
       <alpha> <input CSV> <output folder> [<B> <Delta> <quantile start> <quantile end> <quantile step>]")
}

alpha <- as.numeric(args[1])
if (is.na(alpha) || alpha >= 1) {
  stop("Alpha should be a numeric value less than 1.")
}

input_file <- args[2]
output_folder <- args[3]
input_filename <- basename(input_file)
output_file <- file.path(output_folder, paste0("output_", input_filename))

B <- if (length(args) >= 4) as.numeric(args[4]) else 10000
Delta <- if (length(args) >= 5) as.numeric(args[5]) else 100
quant_start <- if (length(args) >= 6) as.numeric(args[6]) else 0.05
quant_end <- if (length(args) >= 7) as.numeric(args[7]) else 0.95
quant_step <- if (length(args) >= 8) as.numeric(args[8]) else 0.01
quantiles <- seq(quant_start, quant_end, by = quant_step)

# ---- Detect Header and Read Input Data ----
has_header <- function(file_path) {
  first_row <- read.csv(file_path, nrows = 1, header = FALSE, stringsAsFactors = FALSE)
  any(is.na(suppressWarnings(as.numeric(first_row))))
}

header_present <- has_header(input_file)
data <- read.csv(input_file, header = header_present, stringsAsFactors = FALSE)
colnames(data) <- c("group", "value")

# ---- Split Data into Two Groups ----
unique_groups <- unique(data$group)

if (length(unique_groups) != 2) {
  stop("Exactly two groups required. Found: ", toString(unique_groups))
}

group1_data <- data$value[data$group == unique_groups[1]]
group2_data <- data$value[data$group == unique_groups[2]]
n <- min(length(group1_data), length(group2_data))

# ---- Run the Test ----
result <- algorithm(
  data1 = group1_data,
  data2 = group2_data,
  n = n,
  B = B,
  alpha = alpha,
  quant = quantiles,
  Delta = Delta
)

test_info <- result$test_result
block_size <- result$block_size

# ---- Prepare Output ----
test_stat <- if (test_info$test_adjusted < 0) {
  test_info$test_adjusted
} else {
  max(unlist(test_info$testi)[test_info$imp_indices])
}

output_df <- data.frame(
  test_quantile = test_stat,
  block_size = block_size
)

# ---- Write to Output File ----
write.csv(output_df, file = output_file, row.names = FALSE)
