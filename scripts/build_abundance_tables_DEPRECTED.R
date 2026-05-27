args <- commandArgs(trailingOnly=TRUE)

table_file <- args[1]
fasta_file <- args[2]
tax_file <- args[3]
outdir <- args[4]

library(Biostrings)
library(dplyr)
library(readr)
library(tibble)
library(tidyr)
library(stringr)


###### rutas provisionales para pruebas ##########
tab <- read.delim("results/run_27022026/tables/tmp/feature-table.tsv", skip=1, check.names=FALSE)
seqs <- readDNAStringSet("results/run_27022026/tables/tmp/repseq/dna-sequences.fasta")
tax <- read_tsv("results/run_27022026/tables/tmp/taxonomy/taxonomy.tsv")
outdir <- "results/run_27022026/tables"
metadata <- read_tsv("config/sample_metadata_complete.tsv")
##############################################################################


# read ASV table
#tab <- read.delim(table_file, skip=1, check.names=FALSE)
colnames(tab)[1] <- "#NAME"

write.table(tab,
            file=file.path(outdir,"ASV_table.txt"),
            sep="\t",
            quote=FALSE,
            row.names=FALSE)




# Taxa for each ASV abundance
taxa_names <- tax %>%
  rename(`#NAME` = `Feature ID`) %>%
  select(`#NAME`, Taxon)


taxa_abundance <- left_join(tab, taxa_names, by = "#NAME") |>
select(Taxon, everything(), -`#NAME`) |>
rename(`#NAME` = Taxon) 


# guardar tabla de abundancia con taxonomia
write.table(taxa_abundance,
            file=file.path(outdir,"ASV_taxa_abundance.txt"),
            sep="\t",
            quote=FALSE,
            row.names=FALSE)


# read taxonomy file
# read taxonomy
#tax <- read_tsv(tax_file)

# split taxonomy levels
tax_split <- tax %>%
  rename(`#TAXONOMY` = `Feature ID`) %>%
  separate(Taxon,
           into=c("Kingdom","Phylum","Class","Order","Family","Genus","Species"),
           sep=";",
           fill="right",remove = TRUE) |> 
           mutate(
    across(
      c(Kingdom, Phylum, Class, Order, Family, Genus, Species),
      ~ str_remove(.x, "^[a-z]__")
    )
  ) |>
  select(-Confidence)
# guardar tabla

write.table(tax_split,
            file=file.path(outdir,"Taxonomy_split.txt"),
            sep="\t",
            quote=FALSE,
            row.names=FALSE)



# change metadata

metadata <- metadata %>%
  rename(`#NAME` = SampleID) |>
  select(`#NAME`, Species, Location, group, Sexo)

write.table(metadata,
            file=file.path(outdir,"Metadata_table.txt"),
            sep="\t",
            quote=FALSE,
            row.names=FALSE)






# read sequences
#seqs <- readDNAStringSet(fasta_file)
seq_map <- data.frame(
  ASV = names(seqs),
  Sequence = as.character(seqs)
)

# replace ASV IDs with sequences
tab_seq <- left_join(seq_map, tab, by = c("ASV" = "#NAME"))

tab_seq <- tab_seq |>
rename(`#NAME` = ASV) 



write.table(tab_seq,
            file=file.path(outdir,"ASV_sequence.txt"),
            sep="\t",
            quote=FALSE,
            row.names=FALSE)


