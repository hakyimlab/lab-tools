#this script automatically creates a JSON schema file from a given data file
#run it like:
#Rscript autojson.R <path_of_data_table> <name_of_output_JSON_file>

#!/usr/bin/env Rscript
library(glue)
library(jsonlite)

args <- commandArgs(trailingOnly=TRUE)
table <- read.table(file=args[1], header=TRUE, stringsAsFactors=FALSE, nrows=10)
df <- data.frame()
convertType <- c("double"="FLOAT", "integer"="INTEGER", "character"="STRING", "logical"="BOOLEAN")

for (col in colnames(table))
{
  bqtype <- convertType[typeof(table[,col])]
  new_entry <- data.frame("description"="", "mode"="NULLABLE", "name"=col, "type"=bqtype)
  df <- rbind(df, new_entry, make.row.names=FALSE)
}

writeLines(toJSON(df, pretty=TRUE), args[2])
