
# DOWNLOAD DATA -------------------------------------------

# from http://resource.psychencode.org, more info on study: https://science.sciencemag.org/content/362/6420/eaat8127
# or download from terminal using
# wget "http://resource.psychencode.org/Datasets/Derived/PEC_TWAS_weights.tar.gz"
# Once unzipped, each file in the directory will contain information for a single gene
# When loaded, each .RDat file contains snps (snp info), wgt.matrix (weights), and cv.performance (cross validation) tables
# In the snps table, the first column is chromosome, the fourth is position, the fifth is effect allele, and the sixth is reference allele
# In the wgt.matrix table, the rownames are the snp ids, and the columns are the weights derived from each method for each snp




# LOAD FILE -----------------------------------------------

# open a file using:
setwd("~/Desktop/PEC_TWAS_weights")   # set directory to unzipped folder with all .RDat files
load("ENSG00000000457.wgt.RDat")      # load with name of folder. snps, wgt.matrix, and cv.performance tables can be found in global environment




# LOAD LIBRARIES ------------------------------------------

library(RSQLite)
library(tidyverse)
library(data.table)




# CONVERT FILE TO DATA FRAME ------------------------------

# (for a single gene)
# input is the name of the .RDat file (string),
# returns dataframe with gene, position, chromosome, ref allele, eff allele, and non-zero enet weights
make_df <- function(file) {
  load(file)                                            # first, load .RDat file, and define snps and wgt.matrix table as dataframes
  weights <- data.frame(wgt.matrix)                     # contains weights determined by top1, blup, bslmm, lasso, enet
  snps <- data.frame(snps)                              # contains chr, pos, ref and eff alleles
  rownames(weights) <- c()                              # remove rownames from weights
  weights$gene <- substr(file, 1, nchar(file) - 9)      # define gene column by stripping .wgt.RDat from file name
  weights$chromosome <- snps$V1                         # define chr, pos, ref and eff alleles from snps table
  weights$position <- snps$V4
  weights$ref_allele <- snps$V6
  weights$eff_allele <- snps$V5
# filter for non-zero weights, then return weights table with gene, chr, pos, reference, effect, and enet
  weights %>% filter(enet != 0) %>% select(gene, chromosome, position, ref_allele, eff_allele, enet)
}




# WRITE WEIGHTS TABLE -------------------------------------

# Create vector of all .RDat file names in the directory
files <- list.files(pattern = "\\.RDat")

# Write tab delimited file with gene, chr, pos, ref, eff, and enet data for all genes in directory
# first, convert the first file in the vector to dataframe, then write it to a text file
write.table(make_df(files[1]), "pre_weights.txt", sep = "\t", quote = FALSE, row.names = FALSE)
# for remaining files, convert to dataframe, then append it to the same text file
for(i in 2:length(files)) {
  write.table(make_df(files[i]), "pre_weights.txt", append = TRUE, sep = "\t", quote = FALSE, col.names = FALSE, row.names = FALSE)
}




# ADD RSID ------------------------------------------------

# Following Yanyu's recommendation, rsids were added to pre_weights.txt using her python script and a hg19 lookup table
# script: https://github.com/liangyy/misc-tools/tree/master/annotate_snp_by_position
# lookup table, dbSNP150_list.txt, contains chromosome, position, ref, alt, rsid, and dbSNPBuildID
# run:
# python3 annotate_snp_by_position.py \
# --input psychencode.txt.gz --chr_col 2 --pos_col 3 \
# --lookup_table dbSNP150_list.txt.gz --lookup_chr_col 1 --lookup_start_col 2 --lookup_end_col 2 --lookup_newid_col 5 --if_input_has_header 1 \
# --out_txtgz weights_out.txt.gz




# ADD VARIDs ----------------------------------------------

weights <- fread("weights_out.txt")
# Generate varID from chr, pos, ref, eff, and build # (b37)
weights$varID <- paste(weights$chromosome, weights$position, weights$ref_allele, weights$eff_allele, "b37", sep = "_")
# modify columns to match PrediXcan format
weights <- weights %>% select(gene, rsid, varID, ref_allele, alt_allele, enet) %>% rename(weight = enet, rsid = new_id)




# CREATE EXTRA TABLE --------------------------------------

# Generate number of snps for each gene
extra <- weights %>% group_by(gene) %>% summarise(n.snps.in.model = n())
# Create blank columns and reorder to match PrediXcan format
# extra should have header gene, genename, n.snps.in.model, pred.perf.R2, pred.perf.pval.pred.perf.pval
extra$genename <- NA
extra$pred.perf.R2 <- NA
extra$pred.perf.pval <- NA
extra$pred.perf.qval <- NA
extra <- extra[c(1, 3, 2, 4, 5, 6)]




# WRITE TO SQLITE DATABASE --------------------------------

# Create database connection (should also create psychencode.db file in directory)
conn <- dbConnect(RSQLite::SQLite(), "psychencode.db")
# Write weights and extra tables to database
dbWriteTable(conn, "weights", weights)
dbWriteTable(conn, "extra", extra)

# Check that SQLite database is as expected:
# Show tables in database
dbListTables(conn)
# Show contents of weights and extra tables
dbGetQuery(conn, 'SELECT * FROM weights') %>% head
dbGetQuery(conn, 'SELECT * FROM extra') %>% head

# Disconnect from database connection
dbDisconnect(conn)
