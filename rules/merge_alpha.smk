

rule merge_alpha:
    input:
        metadata=config["metadata"],
        shannon="results/{run_name}/core_metrics/shannon_vector.qza",
        features="results/{run_name}/core_metrics/observed_features_vector.qza",
        evenness="results/{run_name}/core_metrics/evenness_vector.qza",
        faith="results/{run_name}/core_metrics/faith_pd_vector.qza"
    output:
        alpha_index="results/{run_name}/alpha_significance/alpha_index_final.tsv"
    script:
        "../scripts/merge_alpha_indices.R"
