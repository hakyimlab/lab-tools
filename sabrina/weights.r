library(RSQLite)
library(tidyverse)

setwd("~/Desktop/PEC_TWAS_weights")

# make dataframe 
# load("ENSG00000000457.wgt.RDat")
make_df <- function(file) {
  load(file)
  weights <- data.frame(wgt.matrix)
  for(i in 1:nrow(weights)) {
    gene <- c(substr(file, 1, nchar(file) - 9))
  }
  weights$gene <- gene
  weights$variant <- rownames(weights)
  rownames(weights) <- c()
  weights %>% select(gene, variant, top1, blup, bslmm)
}

# append files

files <- list.files(pattern = "\\.RDat")


