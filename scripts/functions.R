suppressMessages(library(np))
suppressMessages(library(robcp))
suppressMessages(library(Qtools))

# Compute quantiles, using midquantile for discrete data
compute_quantiles <- function(data, quant, continuous) {
  if (continuous) {
    quantile(data, probs = quant, names = FALSE, type = 2)
  } else {
    midquantile(data, probs = quant)$y
  }
}

# Compute optimal block size using b.star from robcp
compute_block_size <- function(data1, data2) {
  b1 <- b.star(data1)[, 1]
  b2 <- b.star(data2)[, 1]
  ceiling(max(c(b1, b2)))
}

# Determine if data should be considered continuous
is_continuous <- function(data1, data2) {
  min(length(unique(data1)) / length(data1),
      length(unique(data2)) / length(data2)) >= 0.1
}

# Main algorithm to perform robust quantile comparison test
algorithm <- function(data1, data2, n, B, alpha, quant, Delta) {
  continuous <- is_continuous(data1, data2)
  
  q1 <- compute_quantiles(data1, quant, continuous)
  q2 <- compute_quantiles(data2, quant, continuous)
  
  block_size <- compute_block_size(data1, data2)
  
  result <- max_test(
    data1, data2, q1, q2, n, B, alpha, quant,
    block_size, continuous, Delta
  )
  
  list(
    test_result = result,
    block_size = block_size
  )
}

# Quantile-based test statistic with block bootstrap adjustment
max_test <- function(data1, data2, q1, q2, n, B, alpha, quant, m, continuous, Delta) {
  diff <- q1 - q2
  test_quantiles <- abs(diff)
  
  
  bootstrap_samples <- replicate(B,
              bootstrap_max(data1, data2, n, quant, diff, m, continuous, Delta)
  )
 
  sigma_sq <- apply(bootstrap_samples, 1, var)
  bootstrap_samples <- bootstrap_samples / sqrt(sigma_sq)
  
  lrsd1 <- lrv(data1)
  lrsd2 <- lrv(data2)
  
  testi <- numeric(length(quant))
  for (i in seq_along(quant)) {
    qqq <- quant[i]
    shape1 <- floor(qqq * n)
    
    correction <- sqrt(max(sd(data1), sd(data2))) *
      (1 - pbeta(qqq, shape1, n)) / sqrt(qqq * (1 - qqq))
    
    adjustment <- if (continuous) {
      test_quantiles[i] - Delta - correction
    } else {
      sqrt(n) * (test_quantiles[i] - Delta - correction)
    }
    
    testi[i] <- adjustment / sqrt(sigma_sq[i])
  }
  
  valid_indices <- which(sigma_sq <= 5 * mean(sigma_sq))
  crit_condition <- test_quantiles[valid_indices] / sqrt(sigma_sq[valid_indices]) +
    30 * sqrt(log(n)^(3/2) / n) >= Delta / sqrt(sigma_sq[valid_indices])
  
  common_indices <- if (length(crit_condition) > 0) {
    valid_indices[crit_condition]
  } else {
    valid_indices
  }
  
  test_stat <- max(testi[common_indices])
  max_boot <- if (length(common_indices) == 1) {
    bootstrap_samples
  } else {
    apply(bootstrap_samples[common_indices, ], 2, max)
  }
  
  threshold <- quantile(max_boot, 1 - alpha)
  imp_indices <- which(testi[common_indices] >= threshold)
  
  list(
    test_adjusted = test_stat - threshold,
    testi = (test_quantiles - Delta)[common_indices],
    imp_indices = imp_indices
  )
}

# Compute test statistic for bootstrapped continuous data
test_statistic_max_boot_Delta <- function(data1, data2, quant, t1, continuous) {
  q1 <- compute_quantiles(data1, quant, continuous)
  q2 <- compute_quantiles(data2, quant, continuous)
  abs(q1 - q2-t1)
}

# Compute test statistic for bootstrapped discrete data
test_statistic_max_boot_disc_Delta <- function(data1, data2, quant, t1, continuous) {
  m1 <- length(data1)
  q1 <- compute_quantiles(data1, quant, continuous)
  q2 <- compute_quantiles(data2, quant, continuous)
  sqrt(m1) * (abs(q1 - q2-t1))
}
test_statistic_max_boot <- function(data1, data2, quant, t1, continuous) {
  q1 <- compute_quantiles(data1, quant, continuous)
  q2 <- compute_quantiles(data2, quant, continuous)
  abs(q1 - q2) - abs(t1)
}

# Compute test statistic for bootstrapped discrete data
test_statistic_max_boot_disc <- function(data1, data2, quant, t1, continuous) {
  m1 <- length(data1)
  q1 <- compute_quantiles(data1, quant, continuous)
  q2 <- compute_quantiles(data2, quant, continuous)
  sqrt(m1) * (abs(q1 - q2) - abs(t1))
}


# Block bootstrap sampling for max test
bootstrap_max <- function(data1, data2, n, quant, t1, m, continuous,Delta) {
  if (continuous) {
    num_samples <- ceiling(n / m)
    sample_indices <- sample(1:(n - m + 1), num_samples, replace = TRUE)
  } else {
    m1 <- n^(2 / 3)
    num_samples <- ceiling(m1 / m)
    sample_indices <- sample(1:(m1 - m + 1), num_samples, replace = TRUE)
  }
  
  all_indices <- unlist(lapply(sample_indices, function(i) i:(i + m - 1)))
  
  data1_star <- data1[all_indices]
  data2_star <- data2[all_indices]
  
  if (continuous) {
       if(Delta>0){
           test_statistic_max_boot(data1_star, data2_star, quant, t1, continuous)
        } else {
           test_statistic_max_boot_Delta(data1_star, data2_star, quant, t1, continuous)
        }
  } else {
    if(Delta>0){
      test_statistic_max_boot_disc(data1_star, data2_star, quant, t1, continuous)
    } else {
      test_statistic_max_boot_disc_Delta(data1_star, data2_star, quant, t1, continuous)
    }
  }

}
