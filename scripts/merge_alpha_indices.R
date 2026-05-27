### ================================
### 1. Instalar paquetes si faltan
### ================================


### Cargar librerías
library(here)
library(dplyr)
library(qiime2R)
library(pairwiseAdonis)
library(readr)
library(tibble)


### ================================
### 2. Leer metadata
### ================================

#metadata <- read_tsv(here("config/sample_metadata_complete.tsv"))
metadata <- read_tsv(snakemake@input[["metadata"]])

### ================================
### 3. Función para leer archivos alpha
### ================================

read_alpha <- function(path) {
  read_qza(path)$data |> 
    rownames_to_column("SampleID")
}

### ================================
### 4. Cargar índices de diversidad alfa
### ================================

shannon  <- read_alpha(snakemake@input[["shannon"]])

features <- read_alpha(snakemake@input[["features"]]) |>
  mutate(observed_features = as.numeric(observed_features))

evenness <- read_alpha(snakemake@input[["evenness"]])

faith <- read_qza(snakemake@input[["faith"]])$data |>
  rownames_to_column("SampleID") |>
  mutate(faith_pd = as.numeric(faith_pd))



### ================================
### 5. Unir todos los índices
### ================================

alpha_index <- metadata |> 
  inner_join(shannon,   by = "SampleID") |>
  inner_join(features,  by = "SampleID") |>
  inner_join(evenness,  by = "SampleID") |>
  #inner_join(simpson,   by = "SampleID") |>
  inner_join(faith,     by = "SampleID") 

### ================================
### 6. Exportar archivo final
### ================================

write_tsv(alpha_index, snakemake@output[["alpha_index"]])

message("✔ Alpha diversity table generated: ", snakemake@output[["alpha_index"]])