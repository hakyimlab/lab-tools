library(RSQLite)
library(tidyverse)

setwd("~/Desktop/PEC_TWAS_weights")


# make dataframe with gene, position, chromosome, and non-zero enet weights
# load("ENSG00000000457.wgt.RDat")
make_df <- function(file) {
  load(file)
  weights <- data.frame(wgt.matrix)
  snps <- data.frame(snps)
  rownames(weights) <- c()
  weights$gene <- substr(file, 1, nchar(file) - 9)
  weights$position <- snps$V4
  weights$chromosome <- paste("chr", snps$V1, sep = "")
  weights %>% filter(enet != 0) %>% select(gene, chromosome, position, enet)
}

# append files
files <- list.files(pattern = "\\.RDat")

# connect to database
conn <- dbConnect(RSQLite::SQLite(), "PEC_TWAS_weights.db")
for(i in 1:length(files)) {
  dbWriteTable(conn, "pre_weights", make_df(files[i]), append = TRUE)
}

# load variant specification table
dbWriteTable(conn, "snps_matched", read.delim("snps_matched.txt"))

# weights table from inner join on chromosome and position
weights <- dbGetQuery(conn, 'SELECT gene, rsid, panel_variant_id, non_effect_allele, effect_allele, enet FROM pre_weights 
                      INNER JOIN snps_matched ON pre_weights.chromosome = snps_matched.chromosome and pre_weights.position = snps_matched.position')
weights <- rename(weights, weight = enet, varID = panel_variant_id, ref_allele = non_effect_allele, eff_allele = effect_allele)

# extra table
n.snps <- weights %>% group_by(gene) %>% summarise(n.snps.in.model = n())

# Write database
dbWriteTable(conn, "weights", weights)
dbWriteTable(conn, "extra", n.snps)
# dbGetQuery(conn, 'SELECT * FROM weights') %>% head

dbRemoveTable(conn, "pre_weights")
dbRemoveTable(conn, "snps_matched")

# disconnect
dbDisconnect(conn)
