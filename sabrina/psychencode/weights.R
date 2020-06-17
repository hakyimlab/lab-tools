library(RSQLite)
library(tidyverse)
library(data.table)

setwd("~/Desktop/PEC_TWAS_weights")

# convert .RDat to dataframe with gene, position, chromosome, ref allele, eff allele, and non-zero enet weights ----------
load("ENSG00000000457.wgt.RDat")
make_df <- function(file) {
  load(file)
  weights <- data.frame(wgt.matrix)
  snps <- data.frame(snps)
  rownames(weights) <- c()
  weights$gene <- substr(file, 1, nchar(file) - 9)
  weights$position <- snps$V4
  weights$chromosome <- snps$V1
  weights$ref_allele <- snps$V6
  weights$eff_allele <- snps$V5
  weights %>% filter(enet != 0) %>% select(gene, chromosome, position, ref_allele, eff_allele, enet)
}

# append files
files <- list.files(pattern = "\\.RDat")

# connect to database
conn <- dbConnect(RSQLite::SQLite(), "PEC_TWAS_weights.db")
for(i in 1:length(files)) {
  dbWriteTable(conn, "pre_weights", make_df(files[i]), append = TRUE)
}


# snps_specification table was too large, did not run past here, used awk instead ----------------





# load variant specification table
dbWriteTable(conn, "snps_matched", fread("~/Desktop/lab-tools/sabrina/psychencode/dbSNP150_list.txt", select = c("chromosome", "position", "rsid")))

# weights table from inner join on chromosome and position
weights <- dbGetQuery(conn, 'SELECT gene, rsid, panel_variant_id, ref, alt, enet FROM pre_weights 
                      INNER JOIN snps_matched ON pre_weights.chromosome = snps_matched.chromosome and pre_weights.position = snps_matched.position')
weights <- rename(weights, weight = enet, varID = panel_variant_id)

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
