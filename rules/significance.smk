


# ===============================================================
# RULE: ALPHA_SIGNIFICANCE
# Evalúa diferencias significativas entre grupos en métricas alfa
# ===============================================================
rule alpha_significance:
    input:
        core_metrics = directory("results/{run_name}/core_metrics"),
        metadata = config["metadata"]
    output:
        expand("results/{{run_name}}/alpha_significance/{{metric}}_group_significance.qzv",
               metric=["evenness", "faith_pd", "observed", "shannon"])
    params:
        logs = "results/{run_name}/logs/alpha_significance.log"
    conda:
        "../envs/qiime2.yaml"
    shell:
        """
        mkdir -p results/{wildcards.run_name}/alpha_significance
        qiime diversity alpha-group-significance \
            --i-alpha-diversity {input.core_metrics}/evenness_vector.qza \
            --m-metadata-file {input.metadata} \
            --o-visualization results/{wildcards.run_name}/alpha_significance/evenness_group_significance.qzv

        qiime diversity alpha-group-significance \
            --i-alpha-diversity {input.core_metrics}/faith_pd_vector.qza \
            --m-metadata-file {input.metadata} \
            --o-visualization results/{wildcards.run_name}/alpha_significance/faith_pd_group_significance.qzv

        qiime diversity alpha-group-significance \
            --i-alpha-diversity {input.core_metrics}/observed_features_vector.qza \
            --m-metadata-file {input.metadata} \
            --o-visualization results/{wildcards.run_name}/alpha_significance/observed_group_significance.qzv

        qiime diversity alpha-group-significance \
            --i-alpha-diversity {input.core_metrics}/shannon_vector.qza \
            --m-metadata-file {input.metadata} \
            --o-visualization results/{wildcards.run_name}/alpha_significance/shannon_group_significance.qzv
        """

# ===========================================
# 4️⃣ (Opcional) RULE BETA GROUP SIGNIFICANCE
# ===========================================
rule beta_group_significance:
    input:
        directory("results/{run_name}/core_metrics"),
        #bray="results/{run_name}/core_metrics/bray_curtis_distance_matrix.qza",
        #weighted="results/{run_name}/core_metrics/weighted_unifrac_distance_matrix.qza",
        #unweighted="results/{run_name}/core_metrics/unweighted_unifrac_distance_matrix.qza",
        metadata=config["metadata"]
    output:
        directory("results/{run_name}/beta_significance")
    params:
        group_column=config["group_column"]
    conda:
        "../envs/qiime2.yaml"
    log:
        "results/{run_name}/logs/beta_group_significance.log"
    shell:
        """
        mkdir -p results/{wildcards.run_name}/beta_significance

        qiime diversity beta-group-significance \
            --i-distance-matrix results/{run_name}/core_metrics/bray_curtis_distance_matrix.qza \
            --m-metadata-file {input.metadata} \
            --m-metadata-column {params.group_column} \
            --o-visualization results/{wildcards.run_name}/beta_significance/bray_curtis_group_significance.qzv \
            --p-pairwise

        qiime diversity beta-group-significance \
            --i-distance-matrix results/{run_name}/core_metrics/weighted_unifrac_distance_matrix.qza \
            --m-metadata-file {input.metadata} \
            --m-metadata-column {params.group_column} \
            --o-visualization results/{wildcards.run_name}/beta_significance/weighted_unifrac_group_significance.qzv \
            --p-pairwise

        qiime diversity beta-group-significance \
            --i-distance-matrix results/{run_name}/core_metrics/unweighted_unifrac_distance_matrix.qza \
            --m-metadata-file {input.metadata} \
            --m-metadata-column {params.group_column} \
            --o-visualization results/{wildcards.run_name}/beta_significance/unweighted_unifrac_group_significance.qzv \
            --p-pairwise

        &> {log}
        """

