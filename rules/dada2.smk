
# ===============================================================
# RULE: DADA2
# Denoising, merging y chimera removal para generar ASVs
# ===============================================================
rule dada2:
    input:
        f"results/{run_name}/artifacts/paired-end-demux-trimmed.qza"
    output:
        table="results/{run_name}/artifacts/table.qza",
        seq="results/{run_name}/artifacts/rep-seqs.qza",
        stats="results/{run_name}/artifacts/dada2-stats.qza",
    params:
        trunc_len_f=config["dada2-paired"]["trunc-len-f"],
        trunc_len_r=config["dada2-paired"]["trunc-len-r"],
        trim_left_f=config["dada2-paired"]["trim-left-f"],
        trim_left_r=config["dada2-paired"]["trim-left-r"],
        max_ee_f=config["dada2-paired"]["max-ee-f"],
        max_ee_r=config["dada2-paired"]["max-ee-r"],
        trunc_q=config["dada2-paired"]["trunc-q"],
        min_overlap=config["dada2-paired"]["min-overlap"],
        pooling_method=config["dada2-paired"]["pooling-method"],
        chimera_method=config["dada2-paired"]["chimera-method"],
        min_fold_parent_over_abundance=config["dada2-paired"]["min-fold-parent-over-abundance"],
        n_reads_learn=config["dada2-paired"]["n-reads-learn"],
    threads: 4
    log:
        "results/{run_name}/logs/clustering/dada2.log",
    conda:
        "../envs/qiime2.yaml" 
    shell:
        "qiime dada2 denoise-paired "
        "--i-demultiplexed-seqs {input} "
        "--p-trunc-len-f {params.trunc_len_f} "
        "--p-trunc-len-r {params.trunc_len_r} "
        "--p-trim-left-f {params.trim_left_f} "
        "--p-trim-left-r  {params.trim_left_r} "
        "--p-max-ee-f {params.max_ee_f} "
        "--p-max-ee-r {params.max_ee_r} "
        "--p-trunc-q {params.trunc_q} "
        "--p-min-overlap {params.min_overlap} "
        "--p-pooling-method {params.pooling_method} "
        "--p-chimera-method {params.chimera_method} "
        "--p-min-fold-parent-over-abundance {params.min_fold_parent_over_abundance} "
        "--p-n-threads {threads} "
        "--p-n-reads-learn {params.n_reads_learn} "
        "--o-table {output.table} "
        "--o-representative-sequences {output.seq} "
        "--o-denoising-stats {output.stats} "
        "--verbose 2> {log}"

# ===============================================================
# RULE: VISUALIZE_DADA2
# Genera visualizaciones de las tablas y secuencias producidas por DADA2
# ===============================================================

rule visualize_dada2:
    input:
        table="results/{run_name}/artifacts/table.qza",
        rep_seqs="results/{run_name}/artifacts/rep-seqs.qza",
        denoising_stats="results/{run_name}/artifacts/dada2-stats.qza",
        metadata=config["metadata"]
    output:
        table_viz="results/{run_name}/artifacts/table.qzv",
        rep_seqs_viz="results/{run_name}/artifacts/rep-seqs.qzv",
        stats_viz="results/{run_name}/artifacts/stats.qzv"
    conda:
        "../envs/qiime2.yaml"
    shell:
        """
        mkdir -p results/{run_name}/artifacts

        qiime metadata tabulate \
         --m-input-file {input.denoising_stats} \
         --o-visualization {output.stats_viz}

        # Summarize rep-seqs
        qiime feature-table tabulate-seqs \
         --i-data {input.rep_seqs} \
         --o-visualization {output.rep_seqs_viz}

        qiime feature-table summarize \
         --i-table {input.table} \
         --o-visualization {output.table_viz} \
         --m-sample-metadata-file {input.metadata}
        """



# ────────────────────────────────────────────────
# Export DADA2 stats.qzv
# ────────────────────────────────────────────────
rule export_dada2_stats:
    input:
        "results/{run_name}/artifacts/stats.qzv"
    output:
        metadata_tsv = "results/{run_name}/artifacts/stats_export/metadata.tsv"
    conda:
        "../envs/qiime2.yaml"
    shell:
        """
        qiime tools export \
            --input-path {input} \
            --output-path results/{wildcards.run_name}/artifacts/stats_export
        """

# ────────────────────────────────────────────────
# Export representative sequences rep-seqs.qzv
# ────────────────────────────────────────────────
rule export_rep_seqs:
    input:
        "results/{run_name}/artifacts/rep-seqs.qzv"
    output:
        stats="results/{run_name}/artifacts/rep_seqs_export/descriptive_stats.tsv",
        summary="results/{run_name}/artifacts/rep_seqs_export/seven_number_summary.tsv"

    conda:
        "../envs/qiime2.yaml"
    shell:
        """
        mkdir -p results/{run_name}/artifacts/rep_seqs_export
        qiime tools export \
            --input-path {input} \
            --output-path results/{run_name}/artifacts/rep_seqs_export
        """

# ────────────────────────────────────────────────
# Generate sample frequency table from table.qza
# ────────────────────────────────────────────────

rule tabulate_sample_frequency:
    input:
        "results/{run_name}/artifacts/table.qza"
    output:
        qza = "results/{run_name}/artifacts/sample_frequencies.qza",
        metadata ="results/{run_name}/artifacts/sample_frequencies_export/metadata.tsv"
    conda:
        "../envs/qiime2.yaml"
    shell:
        """
        qiime feature-table tabulate-sample-frequencies \
            --i-table {input} \
            --o-sample-frequencies {output.qza}

        qiime tools export \
            --input-path {output.qza} \
            --output-path results/{run_name}/artifacts/sample_frequencies_export

        """


rule clean_exported_tables:
    input:
        repseqs="results/{run_name}/artifacts/rep_seqs_export/seven_number_summary.tsv",
        frequencies="results/{run_name}/artifacts/sample_frequencies_export/metadata.tsv",
        stats="results/{run_name}/artifacts/stats_export/metadata.tsv",
        repseqs_summary="results/{run_name}/artifacts/rep_seqs_export/descriptive_stats.tsv",
    output:
        repseqs_clean="results/{run_name}/artifacts/clean/repseqs_clean.tsv",
        frequencies_clean="results/{run_name}/artifacts/clean/frequencies_clean.tsv",
        frequencies_clean_box="results/{run_name}/artifacts/clean/frequencies_clean_box.tsv",
        features_clean="results/{run_name}/artifacts/clean/features_clean.tsv",
        stats_clean="results/{run_name}/artifacts/clean/stats_clean.tsv",
        summary_clean="results/{run_name}/artifacts/clean/summary_clean.tsv"
    conda:
        "../envs/qiime2.yaml"
    log:
        "results/{run_name}/logs/clean_tables.log"
    script:
        "../scripts/clean_exported_tables.py"


######### rule checkpoint for DADA2 outputs 
rule checkpoint_dada2:
    input:
        rules.clean_exported_tables.output,
        rules.checkpoint_pre_import.output
    output:
        html = "results/{run_name}/checkpoint/dada2_qc_report.html"
    params:
        config = "config/multiqc_config.yaml"  # path to your custom config
    conda:
        "../envs/qc.yaml"
    shell:
        """
        
        multiqc results/{wildcards.run_name}/artifacts/clean \
            --config {params.config} \
            --filename {output.html} \
            --title "Checkpoint report: DADA2 - {wildcards.run_name}"
        """

# ────────────────────────────────────────────────
# Export ASV counts table (ASV x sample)
# ────────────────────────────────────────────────
rule export_asv_counts:
    input:
        table="results/{run_name}/artifacts/table.qza"
    output:
        biom="results/{run_name}/artifacts/asv_counts/feature-table.biom",
        tsv="results/{run_name}/artifacts/asv_counts/feature-table.tsv"
    conda:
        "../envs/qiime2.yaml"
    shell:
        """
        mkdir -p results/{wildcards.run_name}/artifacts/asv_counts

        # export biom table
        qiime tools export \
            --input-path {input.table} \
            --output-path results/{wildcards.run_name}/artifacts/asv_counts

        # convert biom → tsv
        biom convert \
            -i {output.biom} \
            -o {output.tsv} \
            --to-tsv
        """

# ────────────────────────────────────────────────
# Generate abundance tables and taxonomy tables
# ────────────────────────────────────────────────
rule generate_abundance_tables:
    input:
        table="results/{run_name}/artifacts/table.qza",
        repseq="results/{run_name}/artifacts/rep-seqs.qza",
        taxonomy="results/{run_name}/artifacts/taxonomy.qza"
    output:
        asv="results/{run_name}/tables/ASV_abundance_featureID.txt",
        taxa="results/{run_name}/tables/Taxonomy_featureID.txt",
        asv_seq="results/{run_name}/tables/ASV_abundance_sequence.txt",
        taxa_seq="results/{run_name}/tables/Taxonomy_sequence.txt"
    conda:
        "../envs/qiime2.yaml"
    shell:
        """
        mkdir -p results/{wildcards.run_name}/tables
        mkdir -p results/{wildcards.run_name}/tables/tmp

        # export qiime artifacts
        qiime tools export \
            --input-path {input.table} \
            --output-path results/{wildcards.run_name}/tables/tmp/table

        qiime tools export \
            --input-path {input.repseq} \
            --output-path results/{wildcards.run_name}/tables/tmp/repseq

        qiime tools export \
            --input-path {input.taxonomy} \
            --output-path results/{wildcards.run_name}/tables/tmp/taxonomy

        # convert biom to tsv
        biom convert \
            -i results/{wildcards.run_name}/tables/tmp/table/feature-table.biom \
            -o results/{wildcards.run_name}/tables/tmp/feature-table.tsv \
            --to-tsv

        # run R processing
        Rscript {workflow.basedir}/scripts/build_abundance_tables.R \
            results/{wildcards.run_name}/tables/tmp/feature-table.tsv \
            results/{wildcards.run_name}/tables/tmp/repseq/dna-sequences.fasta \
            results/{wildcards.run_name}/tables/tmp/taxonomy/taxonomy.tsv \
            {workflow.basedir}/config/sample_metadata_complete.tsv \
            results/{wildcards.run_name}/tables
        """
