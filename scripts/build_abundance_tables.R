args <- commandArgs(trailingOnly=TRUE)

table_file <- args[1]
fasta_file <- args[2]
tax_file <- args[3]
metadata_file <- args[4]
outdir <- args[5]

library(Biostrings)
library(dplyr)
library(readr)
library(tibble)
library(tidyr)
library(stringr)

dir.create(outdir, showWarnings = FALSE, recursive = TRUE)

# ============================
# 1. ASV abundance (FeatureID)
# ============================

tab <- read.delim(table_file, skip=1, check.names = FALSE)
colnames(tab)[1] <- "#NAME"

write.table(
  tab,
  file = file.path(outdir, "ASV_abundance_featureID.txt"),
  sep = "\t",
  quote = FALSE,
  row.names = FALSE
)

# ============================
# 2. TAXONOMY (FeatureID)
# ============================

tax <- read_tsv(tax_file, show_col_types = FALSE)

tax_split <- tax %>%
  rename(`#TAXONOMY` = `Feature ID`) %>%
  separate(
    Taxon,
    into=c("Kingdom","Phylum","Class","Order","Family","Genus","Species"),
    sep=";",
    fill="right"
  ) %>%
  mutate(
    across(
      c(Kingdom,Phylum,Class,Order,Family,Genus,Species),
      ~str_remove(.x,"^[a-z]__")
    )
  ) %>%
  select(-Confidence)

write.table(
  tax_split,
  file=file.path(outdir,"Taxonomy_featureID.txt"),
  sep="\t",
  quote=FALSE,
  row.names=FALSE
)

# ============================
# 3. METADATA
# ============================

metadata <- read_tsv(metadata_file, show_col_types = FALSE)

metadata <- metadata %>%
  rename(`#NAME` = SampleID) %>%
  select(`#NAME`, everything())

write.table(
  metadata,
  file=file.path(outdir,"Metadata_table.txt"),
  sep="\t",
  quote=FALSE,
  row.names=FALSE
)

# ============================
# 4. ASV abundance (Sequence)
# ============================

seqs <- readDNAStringSet(fasta_file)

seq_map <- tibble(
  FeatureID = names(seqs),
  Sequence = as.character(seqs)
)

tab_seq <- tab %>%
  rename(FeatureID = `#NAME`) %>%
  left_join(seq_map, by="FeatureID") %>%
  select(Sequence, everything(), -FeatureID) %>%
  rename(`#NAME` = Sequence)

write.table(
  tab_seq,
  file=file.path(outdir,"ASV_abundance_sequence.txt"),
  sep="\t",
  quote=FALSE,
  row.names=FALSE
)

# ============================
# 5. TAXONOMY (Sequence)
# ============================

tax_seq <- tax_split %>%
  rename(FeatureID = `#TAXONOMY`) %>%
  left_join(seq_map, by="FeatureID") %>%
  select(Sequence, everything(), -FeatureID) %>%
  rename(`#TAXONOMY` = Sequence)

write.table(
  tax_seq,
  file=file.path(outdir,"Taxonomy_sequence.txt"),
  sep="\t",
  quote=FALSE,
  row.names=FALSE
)