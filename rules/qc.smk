# ===============================================================
# RULE: FASTQC
# Control de calidad de los archivos FASTQ crudos
# ===============================================================

rule fastqc:
    input:
        fastqs = FASTQ_FILES
    output:
        directory(FASTQC_DIR)
    conda:
        "env/qc.yaml"
    threads: 4
    shell:
        """
        mkdir -p {FASTQC_DIR}
        fastqc -t {threads} -o {FASTQC_DIR} {input.fastqs}
        """

# ===============================================================
#  RULE: CUTADAPT
# Recorta adaptadores y primers usando parámetros del config.yaml
# ===============================================================
rule cutadapt:
    input:
        R1 = get_fastq1,
        R2 = get_fastq2
    output:
        R1_trimmed = "results/{run_name}/trimmed/{sample}_R1_trimmed.fastq.gz",
        R2_trimmed = "results/{run_name}/trimmed/{sample}_R2_trimmed.fastq.gz"
    params:
        adapter1=config["adapter1"],
        adapter2=config["adapter2"],
        primer1=config["primertrimming"]["forward"],
        primer2=config["primertrimming"]["reverse"],
        error_rate=config["primertrimming"]["error_rate"],
        min_length=config["primertrimming"]["min_length"]
    log:
        "results/{run_name}/logs/cutadapt/cutadapt_{sample}.log"
    conda:
        "env/qc.yaml"
    threads: 4
    shell:
        """
        mkdir -p results/{run_name}/trimmed
        cutadapt \
         -a {params.adapter1} \
         -A {params.adapter2} \
         -g {params.primer1} \
         -G {params.primer2} \
         -m {params.min_length} \
         -o {output.R1_trimmed} \
         -p {output.R2_trimmed} \
            {input.R1} {input.R2} \
         --cores={threads} > {log}
        """

# ===============================================================
# RULE: MAKE_MANIFEST
# Genera el archivo manifest.tsv requerido por QIIME2
# ===============================================================
rule make_manifest:
    input:
        R1 = TRIMMED_R1,
        R2 = TRIMMED_R2
    output:
        manifest = f"results/{run_name}/metadata/manifest.tsv"
    run:
        import os
        import pandas as pd

        os.makedirs(os.path.dirname(output.manifest), exist_ok=True)

        df = pd.DataFrame({
            "sample-id": SAMPLES,
            "forward-absolute-filepath": [
                os.path.abspath(f"results/{run_name}/trimmed/{s}_R1_trimmed.fastq.gz") for s in SAMPLES
            ],
            "reverse-absolute-filepath": [
                os.path.abspath(f"results/{run_name}/trimmed/{s}_R2_trimmed.fastq.gz") for s in SAMPLES
            ]
        })
        df.to_csv(output.manifest, sep="\t", index=False)

# ===========================================
# ✅ CHECKPOINT: MultiQC reportes pre-import
# ===========================================

rule checkpoint_pre_import:
    input:
        fastqc_dir = FASTQC_DIR,
        cutadapt_logs = expand("results/{run_name}/logs/cutadapt/cutadapt_{sample}.log", sample=SAMPLES, run_name=run_name)
    output:
        fastqc_report = f"results/{run_name}/checkpoint/checkpoint_fastqc.html",
        cutadapt_report = f"results/{run_name}/checkpoint/checkpoint_cutadapt.html"
    conda:
        "env/qc.yaml"  # MultiQC suele estar en este entorno
    threads: 4
    shell:
        """
        mkdir -p results/{run_name}/checkpoint

        # 1. Generar reporte para los resultados de FastQC
        multiqc {input.fastqc_dir} \
            --outdir results/{run_name}/checkpoint \
            --filename checkpoint_fastqc.html

        # 2. Generar reporte para los logs de Cutadapt
        multiqc results/{run_name}/logs/cutadapt \
            --outdir results/{run_name}/checkpoint \
            --filename checkpoint_cutadapt.html
        """




