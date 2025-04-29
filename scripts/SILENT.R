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

start_time <- Sys.time()

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

test_info  <- result$test_result
block_size <- result$block_size
test_stat  <- test_info$test_stat
threshold  <- test_info$threshold
test_adjusted <- test_stat - threshold  # Correct computation


if (!requireNamespace("cli", quietly = TRUE)) install.packages("cli")
if (!requireNamespace("glue", quietly = TRUE)) install.packages("glue")

library(cli)
library(glue)
cli_h2("🗂  Input and Output Paths")
cli_text(glue("• Input file            : {input_file}"))
cli_text(glue("• Output folder         : {output_folder}"))

cli_h2("📈 Summary Statistics")

summarize_group <- function(x, group_name) {
  cli_h3(glue("{group_name} (n = {length(x)})"))
  
  summary_x <- summary(x)
  print(summary_x)
  
  cat("\n")  # after summary
  
  cat(sprintf("  Standard Deviation : %.2f\n", sd(x)))
  cat(sprintf("  Interquartile Range: %.2f\n\n", IQR(x)))
}
summarize_group(group1_data, glue("Group 1 ({unique_groups[1]})"))
summarize_group(group2_data, glue("Group 2 ({unique_groups[2]})"))

cli_h1("📊 Robust Quantile Test Summary")

cli_text(glue("• Alpha level (significance) : {alpha}"))
cli_text(glue("• Number of bootstrap samples: {B}"))
cli_text(glue("• Delta (minimum detectable difference): {Delta}"))
cli_text(glue("• Estimated block size (m) : {block_size}"))

cli_h2("🎯 Detailed Test Results")

cli_text(glue(
  "Test statistic: {round(test_stat, 3)}, ",
  "Threshold: {round(threshold, 3)}, ",
  "Difference: {round(test_adjusted, 3)}"
))

if (test_adjusted > 0) {
  cli_alert_danger("→ Decision: Rejected null hypothesis (significant difference / timing side-channel discovered)")
} else {
  cli_alert_success("→ Decision: Failed to reject null hypothesis (no significant difference / no timing side-channel discovered)")
}

if (!requireNamespace("jsonlite", quietly = TRUE)) install.packages("jsonlite")
library(jsonlite)
end_time <- Sys.time()
elapsed_time <- difftime(end_time, start_time, units = "secs")

# Create list for JSON
result_list <- list(
  input = list(
    input_file = input_file,
    alpha = alpha,
    bootstrap_samples = B,
    delta = Delta,
    block_size = block_size
  ),
  test_result = list(
    test_statistic = round(test_stat, 3),
    threshold = round(threshold, 3),
    adjusted_statistic = round(test_adjusted, 3),
    decision = if (test_adjusted > 0) {
      "Rejected"
    } else {
      "Failed to reject"
    }
  ),
  run_info = list(
    computation_time = as.character(elapsed_time)
  )
)

# Extract base filename without .csv
base_name <- tools::file_path_sans_ext(basename(input_file))

# Construct JSON output file path
json_output_file <- file.path(output_folder, paste0(base_name, "_summary_results.json"))

# Then save JSON as usual
write_json(result_list, path = json_output_file, pretty = TRUE, auto_unbox = TRUE)

cli_alert_success(glue("✅ JSON summary written to {json_output_file}"))

