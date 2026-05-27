# ===============================================================
# RULE: IMPORT_QIIME2
# Importa los FASTQ recortados a un artefacto QIIME2
# ===============================================================

rule import_qiime2:
    input:
        manifest = f"results/{run_name}/metadata/manifest.tsv",
        multiqc = rules.checkpoint_pre_import.output #to ensure checkpoint is done before import
    output:
        qiime2_artifact = f"results/{run_name}/artifacts/paired-end-demux-trimmed.qza"
    conda:
        "../envs/qiime2.yaml"
    shell:
        """
        mkdir -p results/{run_name}/artifacts
        qiime tools import \
         --type 'SampleData[PairedEndSequencesWithQuality]' \
         --input-path {input.manifest} \
         --output-path {output.qiime2_artifact} \
         --input-format PairedEndFastqManifestPhred33V2
        """


# ===============================================================
# RULE: SUMMARIZE_DEMUX
# Genera una visualización (.qzv) del archivo demultiplexado (.qza)
# ===============================================================

rule summarize_demux:
    input:
        demux_qza = f"results/{run_name}/artifacts/paired-end-demux-trimmed.qza"
    output:
        demux_qzv = f"results/{run_name}/artifacts/paired-end-demux-trimmed.qzv"
    conda:
        "../envs/qiime2.yaml"
    shell:
        """
        qiime demux summarize \
            --i-data {input.demux_qza} \
            --o-visualization {output.demux_qzv}
        """
