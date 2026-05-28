# ===============================================================
# RULE: DOWNLOAD SILVA DATABASE
# Descarga automáticamente el clasificador SILVA si no existe
# ===============================================================

if config["database"]["SILVA"] == True:

    rule download_silva:
        output:
            classifier = config["database"]["SILVA_path"]
        params:
            url = config["database"]["SILVA_url"]
        conda:
            "../envs/utils.yaml"
        shell:
            """
            mkdir -p databases

            wget -O {output.classifier} {params.url}
            """


    # ===============================================================
    # RULE: ASSIGN TAXONOMY
    # Clasificación taxonómica con SILVA
    # ===============================================================

    rule assign_taxonomy:
        input:
            rep_seqs = "results/{run_name}/artifacts/rep-seqs.qza",
            classifier = rules.download_silva.output.classifier
        output:
            taxonomy = "results/{run_name}/artifacts/taxonomy.qza",
            taxonomy_viz = "results/{run_name}/artifacts/taxonomy.qzv"
        threads: 6
        conda:
            "../envs/qiime2.yaml"
        shell:
            """
            qiime feature-classifier classify-sklearn \
              --i-classifier {input.classifier} \
              --i-reads {input.rep_seqs} \
              --o-classification {output.taxonomy}

            qiime metadata tabulate \
              --m-input-file {output.taxonomy} \
              --o-visualization {output.taxonomy_viz}
            """
# ===============================================================
# RULE: PHYLOGENY
# Construye árboles filogenéticos de las ASVs para métricas de diversidad filogenética
# ===============================================================
rule phylogenetic_tree:
    input:
        rep_seqs = "results/{run_name}/artifacts/rep-seqs-taxfiltered.qza"
    output:
        rooted_tree = "results/{run_name}/artifacts/rooted-tree.qza",
        unrooted_tree = "results/{run_name}/artifacts/unrooted-tree.qza"
    conda:
        "../envs/qiime2.yaml"
    shell:
        """
        qiime phylogeny align-to-tree-mafft-fasttree \
          --i-sequences {input.rep_seqs} \
          --o-alignment results/{wildcards.run_name}/artifacts/aligned-rep-seqs.qza \
          --o-masked-alignment results/{wildcards.run_name}/artifacts/masked-aligned-rep-seqs.qza \
          --o-tree {output.unrooted_tree} \
          --o-rooted-tree {output.rooted_tree}
        """




# --------------------------------------------------------------
# Rule: taxonomy_barplot
# --------------------------------------------------------------
rule taxonomy_barplot:
    input:
        table ="results/{run_name}/artifacts/table-taxfiltered.qza",
        taxonomy = "results/{run_name}/artifacts/taxonomy.qza",
        metadata = config["metadata"]
    output:
        directory("results/{run_name}/taxonomy_barplots")
    conda:
        "../envs/qiime2.yaml"
    log:
        "results/{run_name}/logs/taxonomy_barplot.log"
    shell:
        """
        mkdir -p results/{wildcards.run_name}/taxonomy_barplots
        mkdir -p results/{wildcards.run_name}/checkpoint/taxa_barplots

        qiime taxa barplot \
            --i-table {input.table} \
            --i-taxonomy {input.taxonomy} \
            --m-metadata-file {input.metadata} \
            --o-visualization results/{wildcards.run_name}/taxonomy_barplots/taxa-bar-plots.qzv \
            &> {log}

        qiime tools export \
            --input-path results/{wildcards.run_name}/taxonomy_barplots/taxa-bar-plots.qzv \
            --output-path results/{wildcards.run_name}/checkpoint/taxa_barplots

        mv results/{wildcards.run_name}/checkpoint/taxa_barplots/index.html results/{wildcards.run_name}/checkpoint/taxa_barplots/taxa_barplots_report.html
        """


# ===============================================================
# RULE: FILTER_TAXONOMY
# Permite filtrar taxones no deseados de la tabla y secuencias
# ===============================================================
rule filter_taxonomy:
    input:
        table = lambda wc: get_table(wc.run_name),
        seqs = lambda wc: get_repseqs(wc.run_name),
        taxonomy = "results/{run_name}/artifacts/taxonomy.qza"
    output:
        table = "results/{run_name}/artifacts/table-taxfiltered.qza",
        seqs = "results/{run_name}/artifacts/rep-seqs-taxfiltered.qza"
    params:
        exclude = config["taxonomy_filter"]["exclude"] # puedes añadir más taxones aquí
    log:
        "results/{run_name}/logs/filter_taxonomy.log"
    conda:
        "../envs/qiime2.yaml"
    shell:
        """
        echo "Filtering unwanted taxa: {params.exclude}" > {log}

        qiime taxa filter-table \
            --i-table {input.table} \
            --i-taxonomy {input.taxonomy} \
            --p-exclude {params.exclude} \
            --o-filtered-table {output.table} \
            --verbose 2>> {log}

        qiime taxa filter-seqs \
            --i-sequences {input.seqs} \
            --i-taxonomy {input.taxonomy} \
            --p-exclude {params.exclude} \
            --o-filtered-sequences {output.seqs} \
            --verbose 2>> {log}
        """



