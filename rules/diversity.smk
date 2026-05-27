
# ===========================================
# 3️⃣ RULE ALPHA DIVERSITY ANALYSES
rule alpha_rarefaction_curve:
    input:
        table = "results/{run_name}/artifacts/table-taxfiltered.qza",
        rep_seqs = "results/{run_name}/artifacts/rep-seqs-taxfiltered.qza",
        metadata = config["metadata"],
        rooted_tree = "results/{run_name}/artifacts/rooted-tree.qza"
    output:
        rarefaction_qzv = "results/{run_name}/artifacts/alpha-rarefaction.qzv"
    params:
        max_depth = config["depth"]  # Adjust based on your data
    conda:
        "env/qiime2.yaml"
    shell:
        """
        qiime diversity alpha-rarefaction \
            --i-table {input.table} \
            --i-phylogeny {input.rooted_tree} \
            --m-metadata-file {input.metadata} \
            --p-max-depth {params.max_depth} \
            --o-visualization {output.rarefaction_qzv}


        # exportar la visualizacion a la carpeta de checkpoints
        qiime tools export \
            --input-path {output.rarefaction_qzv} \
            --output-path results/{wildcards.run_name}/checkpoint/alpha_rarefaction_exported
            
        mv results/{wildcards.run_name}/checkpoint/alpha_rarefaction_exported/index.html results/{wildcards.run_name}/checkpoint/alpha_rarefaction_exported/alpha_rarefaction.html
        """


# ===============================================================
# RULE: CORE_METRICS
# Calcula diversidad alfa y beta, y genera matrices de distancia
# ===============================================================

rule core_metrics:
    input:
        table = "results/{run_name}/artifacts/table-taxfiltered.qza",
        metadata = config["metadata"],
        rooted_tree = "results/{run_name}/artifacts/rooted-tree.qza"
    output:
        directory("results/{run_name}/core_metrics")
    params:
        depth = config["depth"],
        threads = 8,
        logs = "results/{run_name}/logs/core_metrics.log"
    conda:
        "env/qiime2.yaml"
    shell:
        """
            qiime diversity core-metrics-phylogenetic \
            --i-phylogeny {input.rooted_tree} \
            --i-table {input.table} \
            --p-sampling-depth {params.depth} \
            --m-metadata-file {input.metadata} \
            --output-dir {output} \
            --p-n-jobs-or-threads {params.threads} \
            --verbose \
            &> {params.logs}
        """
