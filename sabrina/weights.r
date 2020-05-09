library(RSQLite)
library(tidyverse)

setwd("~/Desktop/PEC_TWAS_weights")


# make dataframe 
# load("ENSG00000000457.wgt.RDat")
make_df <- function(file) {
  load(file)
  weights <- data.frame(wgt.matrix)
  snps <- data.frame(snps)
  rownames(weights) <- c()
  weights$gene <- substr(file, 1, nchar(file) - 9)
  weights$variant <- paste(snps$V2, snps$V5, snps$V6, sep=":")
  weights %>% filter(enet != 0) %>% select(gene, variant, enet)
}

# append files
files <- list.files(pattern = "\\.RDat")

# connect to database
conn <- dbConnect(RSQLite::SQLite(), "PEC_TWAS_weights.db")
for(i in 1:length(files)) {
  dbWriteTable(conn, "weights", make_df(files[i]), append = TRUE)
}

dbWriteTable(conn, "snps_matched", read.delim("snps_matched.txt"))

weights_df <- dbGetQuery(conn, 'SELECT gene, rsid, panel_variant_id, non_effect_allele, effect_allele, enet FROM weights INNER JOIN snps_matched on weights.variant = snps_matched.variant')
weights_df <- rename(weights_df, weight = enet, varID = panel_variant_id)
n.snps <- weights_df %>% group_by(gene) %>% summarise(n.snps.in.model = n())
# weights_df <- dbGetQuery(conn, 'SELECT gene, rsid, varID, non_effect_allele, effect_allele, weight FROM weights')

dbWriteTable(conn, "weights", weights_df, overwrite= TRUE)
dbRemoveTable(conn, "snps_matched")
# disconnect
dbDisconnect(conn)
