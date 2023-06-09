# load_inputs.R ----
# Loads SNP presence/absence matrix and phenotypic data
# nicolas.godron@gmail.com

# INPUT:
# Directory path (char)
# SNP presence/absence tab-separated file path (char)
# Phenotype tab-separated file path (char)
# Phenotype column index or name (int | char)
# Optional: Covariate column(s) (int | char, combined with c() or not)

# OUPUT:
# Matrix of SNP absence/presence
# (1D) matrix of phenotype
# Optional: Covariate column(s) 

## Testing completeness of given arguments ----

if (is.na(arguments$snp)) {
  stop("Path to SNP file was not provided (2nd trailing argument)")
}
    
if (is.na(arguments$pheno)) {
  stop("Path to phenotype file was not provided (3rd trailing argument)")
}

if (!is.na(arguments$dir)) {
  arguments$snp <- paste0(arguments$dir, arguments$snp)
  arguments$pheno <- paste0(arguments$dir, arguments$pheno)
  arguments$cost <- paste0(arguments$dir, arguments$cost)
} # else arguments$snp, arguments$pheno & arguments$weights are absolute paths

if (! file.exists(arguments$snp)) {
  stop("The provided path of SNPs does not lead to a readable file.")
}
if (! file.exists(arguments$pheno)) {
  stop("The provided path of phenotypes does not lead to a readable file.")
}
# if (! file.exists(arguments$cost)) {
#   message(
# "The provided path of costs does not lead to a readable file,
# or no costs were provided. The objective function will compute without costs.")
# }


## Input loading ----

input_loading <- function(SNP_path, pheno_path, pheno_index, covar_index = NULL) {
  cat("__Loading inputs__\n\nSNP path:", SNP_path, "\nPheno path:", pheno_path,
      "\nPheno index:", pheno_index, "\nCovar index:", covar_index, "\n")
  
  SNP_matrix <- as.matrix(read.delim(file = SNP_path, row.names = 1))
  
  pheno_file <- read.delim(file = pheno_path, row.names = 1)
  pheno_matrix <- as.matrix(pheno_file[pheno_index])
  pheno_matrix <- as.factor(pheno_matrix)
  
  # In case no covariates are to be added:
  if (is.null(covar_index)) {
    output <- list(SNP_matrix, pheno_matrix)
    return(output) # 2 elements in list
  }

  covar_matrix <- as.matrix(pheno_file[covar_index])

  
  # One-hot encoding of each covariate
  n_values <- 0
  covar_names <- NULL
  for (i in 1:ncol(covar_matrix)) {
    n_values <- n_values + length(unique(covar_matrix[,i]))
    covar_names <- c(covar_names, sort(unique(covar_matrix[,i])))
  }
  
  one_hot <- matrix(nrow = nrow(covar_matrix), ncol = n_values)
  colnames(one_hot) <- covar_names
  
  ### The following one-hot encoding works, but code is dirty!
  col_index <- 1
  
  for (i in 1:ncol(covar_matrix)) {
    column_values <- sort(unique(covar_matrix[,i]))
    
    cat("\nCovariate n°:", col_index, "\nCovariate values:", column_values, "\n\n\n")
    
    for (j in col_index:(col_index+length(column_values)-1)) {
      # print(j)
      covar_value <- column_values[j-col_index+1]
      one_hot[,j] <- covar_matrix[,i] == covar_value
      # print(one_hot[,j])
    }
    col_index <- col_index + length(column_values)
  }
  
  covar_matrix <- one_hot
  
  output <- list(SNP_matrix, pheno_matrix, covar_matrix)
  return(output) # 3 elements in list
}

cost_loading <- function (cost_path, cost_index, covar_names) {
  count_covar <- length(covar_names)
  cost_file <- read.delim(file = cost_path, row.names = 1)
  cost_matrix <- as.matrix(cost_file[cost_index])
  cost_matrix <- rbind(cost_matrix,
                       matrix(data = rep(1, count_covar)))
  dimnames(cost_matrix)[[1]] <- 
    c(dimnames(cost_matrix)[[1]][1:(nrow(cost_matrix)- count_covar)], covar_names)
  
  return(cost_matrix)
}
