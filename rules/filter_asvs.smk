# Solo crear la regla si el usuario activa los filtros
if config["filter_asvs"]["apply"]:

    rule filter_feature_data:
        input:
            table="results/{run_name}/artifacts/table.qza",
            repseqs="results/{run_name}/artifacts/rep-seqs.qza",
            metadata=config["metadata"]
        output:
            filtered_table="results/{run_name}/artifacts/filtered_table.qza",
            filtered_seqs="results/{run_name}/artifacts/filtered_seqs.qza",
            filtered_table_qzv="results/{run_name}/artifacts/filtered_table.qzv",
            filtered_seqs_qzv="results/{run_name}/artifacts/filtered_seqs.qzv"
        params:
            where = config["filter_asvs"]["where"]
        conda: 
            "env/qiime2.yaml"
        shell:
            """
            # Filter samples by location
            qiime feature-table filter-samples \
                --i-table {input.table} \
                --m-metadata-file {input.metadata} \
                --p-where {params.where} \
                --o-filtered-table {output.filtered_table}

            # Filter ASVs by table
            qiime feature-table filter-seqs \
                --i-data {input.repseqs} \
                --i-table {output.filtered_table} \
                --o-filtered-data {output.filtered_seqs}

            # Generate visualizations of filtered data
            qiime feature-table summarize \
                --i-table {output.filtered_table} \
                --o-visualization {output.filtered_table_qzv} \
                --m-sample-metadata-file {input.metadata} 

            qiime feature-table tabulate-seqs \
                --i-data {output.filtered_seqs} \
                --o-visualization {output.filtered_seqs_qzv}
                
            """
