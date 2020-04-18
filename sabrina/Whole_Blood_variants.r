library(RSQLite)
library(tidyverse)

sqlite <- dbDriver("SQLite")
dbname <- "mashr_Whole_Blood.db"

# Create a connection to new database, mashr_Whole_Blood.db
db = dbConnect(sqlite, dbname)

# View tables included in mashr_Whole_Blood.db
dbListTables(db)

# View columns of weights and extra tables
dbListFields(db, "weights")
dbListFields(db, "extra")

# View weights and extra tables from mashr_Whole_Blood.db
weights <- dbGetQuery(db, 'select * from weights')
extra <- dbGetQuery(db, 'select * from extra')
# Load mashr_Whole_Blood and snps_matched dataframes
mashr_Whole_Blood <- read.csv("mashr_Whole_Blood.txt", sep="")
snps_matched <- read.delim("snps_matched.txt")

# Merges weights and snps_matched table by inner joining with varID in weights and panel_variant_id in snps_matched
# each variant with GTEx prediction model (panel_variant_id) is matched to a UK Biobank variant (variant)
merged <- weights %>% inner_join(snps_matched %>% select(variant, panel_variant_id), by=c("varID"="panel_variant_id"))
merged <- merged %>% mutate(varID = variant) %>% select(-variant)

# Update gene and n.snps.in.model column from counts of gene in matched
extra_n.snps <- merged %>% group_by(gene) %>% summarise(n.snps.in.model = n())
updated_extra <- inner_join(extra_n.snps, extra %>% select(-n.snps.in.model), by="gene")

# Write new model
output <- dbConnect(RSQLite::SQLite(), "whole-blood-output.db")
dbWriteTable(output, "weights", merged)
dbWriteTable(output, "extra", updated_extra)

# Update GTEx variant in mashr_Whole_Blood (RSID1 and RSID2) to UKBiobank definition
mapped_Whole_Blood <- inner_join(mashr_Whole_Blood, merged, by=c("RSID1" = "varID")) %>% mutate(RSID1 = variant) %>% select(-variant)
mapped_Whole_Blood <- inner_join(mapped_Whole_Blood, merged, by=c("RSID2" = "varID")) %>% mutate(RSID2 = variant) %>% select(-variant)
mapped_Whole_Blood <- mapped_Whole_Blood %>% select(GENE, variant.x, variant.y, VALUE) %>% rename(RSID1 = variant.x, RSID2 = variant.y) 
write.table(mapped_Whole_Blood, file="mapped_Whole_Blood.txt")
dbDisconnect(db)
dbDisconnect(output)
