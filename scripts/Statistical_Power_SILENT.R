# Load dependencies (if needed)
# library(dplyr)  # Example
# Import helper functions
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

# Check file argument is present
if (length(args) < 1) {
  stop("Usage: Rscript script.R <input_file.csv>")
}

# --------- READ INPUT FILE ------------



read_numeric_cli <- function(prompt_text, default) {
  cat(sprintf("%s [default: %s]: ", prompt_text, default))
  line <- readLines(con = file("stdin"), n = 1)
  
  if (line == "") {
    cat(sprintf("→ Using default value: %s\n", default))
    return(default)
  }
  
  num <- as.numeric(line)
  if (is.na(num)) stop(paste0("❌ Invalid input for: ", prompt_text))
  return(num)
}

# Hybrid input mode: expert via CLI or interactive fallback
args <- commandArgs(trailingOnly = TRUE)

if (length(args) >= 5) {
  input_file <- args[1]
  mu         <- as.numeric(args[2])
  Delta      <- as.numeric(args[3])
  p          <- as.numeric(args[4])
  alpha      <- as.numeric(args[5])
  
  if (anyNA(c(mu, Delta, p, alpha))) {
    stop("❌ Invalid numeric values in expert mode arguments.")
  }
  
  cat("🧠 Running in expert mode with parameters from command line...\n")
  
} else {
  if (length(args) < 1) stop("Usage: Rscript script.R input.csv [mu Delta p alpha]")
  
  input_file <- args[1]
  
  # Interactive fallback
  mu    <- read_numeric_cli("Enter mu (expected size)", default = 2)
  Delta <- read_numeric_cli("Enter Delta (expected bias)", default = 1)
  p     <- read_numeric_cli("Enter desired detection rate p (e.g., 0.9)", default = 0.9)
  alpha <- read_numeric_cli("Enter false positive rate alpha (e.g., 0.05)", default = 0.05)
}



has_header <- function(file) {
  first_row <- read.csv(file, nrows = 1, header = FALSE, stringsAsFactors = FALSE)
  any(is.na(suppressWarnings(as.numeric(first_row))))
}

header_present <- has_header(input_file)

data <- read.csv(file = input_file, header = header_present, stringsAsFactors = FALSE)
# Ensure columns are always named V1 and V2
colnames(data) <- c("V1", "V2")

# Get unique values from data$V1
unique_values <- unique(data$V1)

data1 <- data$V2[data$V1 == unique_values[1]]
data2 <- data$V2[data$V1 == unique_values[2]]
cat("Loaded data with", nrow(data), "rows and", ncol(data), "columns\n")


#use_median   <- read_numeric_cli("Do you expect a shift (type 1)?", default = 1)
qstart   <- 0.1  # fixed, or replace with read_numeric_cli(...)
qend     <- 0.9
stepsize <- 0.1

if (Delta > mu) {
  stop("Delta is greater than mu. We cannot detect a difference.")
}

# 🧾 Display summary before computation
cat("\n📊 Parameters Summary\n")
cat("------------------------------\n")
cat(sprintf("✅ mu (expected effect size)     : %.0f\n", mu))
cat(sprintf("✅ Delta (bias threshold)        : %.0f\n", Delta))
cat(sprintf("✅ p (detection power)           : %.3f\n", p))
cat(sprintf("✅ alpha (false positive rate)   : %.3f\n", alpha))
cat(sprintf("✅ Quantile range                : %.3f to %.3f (step = %.3f)\n", qstart, qend, stepsize))
cat("------------------------------\n")

# 🛠 Computation
cat("⚙️  Computing quantiles and bootstrap estimates...\n")

B <- 1000
quant <- seq(qstart, qend, stepsize)
continuous <- ifelse(is_continuous(data1, data2), TRUE, FALSE)

q1 <- compute_quantiles(data1, quant, continuous)
q2 <- compute_quantiles(data2, quant, continuous)

m <- compute_block_size(data1, data2)
diff <- q1 - q2
n_input <- min(length(data1),length(data2))
bootstrap_samples <- replicate(
  B,
  bootstrap_max(data1, data2, n_input, quant, diff, m, continuous,Delta)
)

sigma_sq <- apply(bootstrap_samples, 1, var)
valid_indices <- which(sigma_sq <= 5 * mean(sigma_sq))

sigma_max <- c(
  median(sqrt(sort(sigma_sq)[1:3])) * sqrt(n_input),
  median(sqrt(sort(sigma_sq)[4:6])) * sqrt(n_input),
  median(sqrt(sort(sigma_sq)[7:9])) * sqrt(n_input)
)




q <- qnorm(1 - p, mean = 0, sd = sigma_max)

n <- (q / sigma_max - (qnorm(1 - alpha) * sigma_max)) / (mu - Delta)

n_final <- ceiling(max(100, n^2))

# 📢 Final Result
cat("\n📈  Power Analysis Result\n")
cat("------------------------------------------\n")
cat(sprintf("🎯 Required sample size (n):\n"))
cat(sprintf("   • Minimum : %.0f\n", ceiling(n[1]^2)))
cat(sprintf("   • Median  : %.0f\n", ceiling(n[2]^2)))
cat(sprintf("   • Maximum : %.0f\n", ceiling(n[3]^2)))

cat("------------------------------------------\n")

if (max(ceiling(n^2)) < 100) {
  cat("💡 Recommendation: Measure at least", ceiling(n[2]^2),
      "samples per group, but recommend:", n_final, "\n\n")
} else {
  cat("💡 Recommendation: Measure at least", ceiling(n[2]^2), "samples per group.\n\n")
}

cat("✅ Analysis complete.\n")
