import pandas as pd
import os


# Cargar archivo de configuración
configfile: "config/config.yaml"


# Definir el nombre de la corrida
run_name = config["run_name"]

# Leer tabla de muestras
SAMPLES_TABLE = pd.read_csv(config["samples_file"], sep="\t", dtype=str)
SAMPLES_TABLE["sample_id"] = SAMPLES_TABLE["sample_id"].str.strip()




# Diccionario de muestras
SAMPLE_DICT = {
    row["sample_id"]: {
        "R1": row["forward-absolute-filepath"],
        "R2": row["reverse-absolute-filepath"],
        "extension": row["file_extension"]
    }
    for _, row in SAMPLES_TABLE.iterrows()
}

# Lista de IDs
SAMPLES = list(SAMPLE_DICT.keys())

# Funciones helper
def get_fastq1(wildcards):
    return str(SAMPLE_DICT[wildcards.sample]["R1"])

def get_fastq2(wildcards):
    return str(SAMPLE_DICT[wildcards.sample]["R2"])

# Lista de FASTQ
FASTQ_FILES = list(SAMPLES_TABLE["forward-absolute-filepath"]) + list(SAMPLES_TABLE["reverse-absolute-filepath"])

# imprimir las muestras cargadas
print("Samples loaded:", SAMPLES)


# Carpeta de resultados
FASTQC_DIR = f"results/{run_name}/fastqc"

# Archivos de salida de cutadapt
TRIMMED_R1 = [f"results/{run_name}/trimmed/{s}_R1_trimmed.fastq.gz" for s in SAMPLES]
TRIMMED_R2 = [f"results/{run_name}/trimmed/{s}_R2_trimmed.fastq.gz" for s in SAMPLES]

FILTER_APPLY = config["filter_asvs"]["apply"]

#definiciones para indicar archivos segun si se aplican filtros de ASVs o no
def get_table(run_name):
    return f"results/{run_name}/artifacts/filtered_table.qza" if FILTER_APPLY \
        else f"results/{run_name}/artifacts/table.qza"

def get_repseqs(run_name):
    return f"results/{run_name}/artifacts/filtered_seqs.qza" if FILTER_APPLY \
        else f"results/{run_name}/artifacts/rep-seqs.qza"


# === INCLUSIÓN DE REGLAS ===
include: "rules/qc.smk"
include: "rules/import.smk"
include: "rules/dada2.smk"
include: "rules/filter_asvs.smk"
include: "rules/taxonomy.smk"
include: "rules/diversity.smk"
include: "rules/significance.smk"
#include: "rules/merge_alpha.smk"



####################################################################
#  RULE ALL: Define todas las salidas finales del flujo de trabajo
####################################################################

rule all:
    input:
        # FastQC generará archivos .html y .zip para cada FASTQ, pero aquí no necesitamos listarlos todos
        # Solo aseguramos que la carpeta exista al final
        FASTQC_DIR,
        TRIMMED_R1,
        TRIMMED_R2,
        #checkpoint outputs
        f"results/{run_name}/checkpoint/checkpoint_fastqc.html",
        f"results/{run_name}/checkpoint/checkpoint_cutadapt.html",

        f"results/{run_name}/metadata/manifest.tsv",
        f"results/{run_name}/artifacts/paired-end-demux-trimmed.qza",
        f"results/{run_name}/artifacts/paired-end-demux-trimmed.qzv",
        # Add DADA2 outputs here
        f"results/{run_name}/artifacts/table.qza",
        f"results/{run_name}/artifacts/rep-seqs.qza",
        f"results/{run_name}/artifacts/dada2-stats.qza",
        f"results/{run_name}/artifacts/table.qzv",
        f"results/{run_name}/artifacts/rep-seqs.qzv",
        f"results/{run_name}/artifacts/stats.qzv",

        f"results/{run_name}/artifacts/table.qza",
        f"results/{run_name}/artifacts/rep-seqs.qza",
        # filtro condicional
        get_table(run_name),
        get_repseqs(run_name),

        # Taxonomy outputs if SILVA is enabled
        f"results/{run_name}/artifacts/taxonomy.qza" if config["database"]["SILVA"] else None,
        f"results/{run_name}/artifacts/taxonomy.qzv" if config["database"]["SILVA"] else None,
        # Phylogenetic tree outputs
        f"results/{run_name}/artifacts/rooted-tree.qza",
        f"results/{run_name}/artifacts/unrooted-tree.qza",
        # MultiQC related outputs ############ remove these later as I will use multiqc report as input
        f"results/{run_name}/artifacts/stats_export/metadata.tsv", # resultado de rule export_dada2_stats
        f"results/{run_name}/artifacts/rep_seqs_export/descriptive_stats.tsv", # resultado de rule export_rep_seqs
        f"results/{run_name}/artifacts/rep_seqs_export/seven_number_summary.tsv", # resultado de rule export_rep_seqs
        f"results/{run_name}/artifacts/sample_frequencies.qza", 
        f"results/{run_name}/artifacts/sample_frequencies_export/metadata.tsv",

        f"results/{run_name}/artifacts/clean/repseqs_clean.tsv",
        f"results/{run_name}/artifacts/clean/frequencies_clean.tsv",
        f"results/{run_name}/artifacts/clean/frequencies_clean_box.tsv",
        f"results/{run_name}/artifacts/clean/stats_clean.tsv",
        f"results/{run_name}/artifacts/clean/summary_clean.tsv",
        f"results/{run_name}/artifacts/asv_counts/feature-table.biom",
        f"results/{run_name}/artifacts/asv_counts/feature-table.tsv",

        #### prueba tablas
        f"results/{run_name}/tables/ASV_abundance_featureID.txt",
        f"results/{run_name}/tables/Taxonomy_featureID.txt",
        f"results/{run_name}/tables/Taxonomy_sequence.txt",


        ## output for checkpoint multiqc report
        f"results/{run_name}/checkpoint/dada2_qc_report.html",
        #taxonomy filters
        f"results/{run_name}/artifacts/table-taxfiltered.qza",
        f"results/{run_name}/artifacts/rep-seqs-taxfiltered.qza",

        # alpha rarefaction curve
        f"results/{run_name}/artifacts/alpha-rarefaction.qzv",
        # core metrics output directory
        f"results/{run_name}/core_metrics",

        # alpha group significance outputs
        f"results/{run_name}/alpha_significance/evenness_group_significance.qzv",
        f"results/{run_name}/alpha_significance/faith_pd_group_significance.qzv",
        f"results/{run_name}/alpha_significance/observed_group_significance.qzv",
        f"results/{run_name}/alpha_significance/shannon_group_significance.qzv",

        # beta group significance output
        f"results/{run_name}/beta_significance",

        # taxonomy barplots
        f"results/{run_name}/taxonomy_barplots"

        #f"results/{run_name}/alpha_significance/alpha_index_final.tsv"




