import pandas as pd
import os

# Redirect stderr to Snakemake log
import sys
sys.stderr = open(snakemake.log[0], "w")

# ───────────────────────────────
# 1️⃣ Clean rep-seqs summary
# ───────────────────────────────
repseqs = pd.read_csv(snakemake.input.repseqs, sep="\t")
# Keep only the 2nd column
if repseqs.shape[1] > 1:
    repseqs_clean = repseqs.iloc[:, [1]]
else:
    repseqs_clean = repseqs.copy()
repseqs_clean.to_csv(snakemake.output.repseqs_clean, sep="\t", index=False)

# ───────────────────────────────
# 2️⃣ Clean sample frequencies
# ───────────────────────────────
freq = pd.read_csv(snakemake.input.frequencies, sep="\t")

# Drop second row (#q2:types)
freq = freq.drop(0, axis=0).reset_index(drop=True)

# Remove thousand separators and convert column 2 to numeric
freq["Frequency"] = freq["Frequency"].astype(str).str.replace(",", "")
freq["Frequency"] = pd.to_numeric(freq["Frequency"], errors="coerce")

# Rename last column
if "No. of Associated Features" in freq.columns:
    freq = freq.rename(columns={"No. of Associated Features": "Features"})

# Keep only the relevant columns
freq = freq.loc[:, ["Sample ID", "Frequency", "Features"]]

# ───────────────────────────────
# Split into two separate tables
# ───────────────────────────────
freq_table = freq.loc[:, ["Sample ID", "Frequency"]]
features_table = freq.loc[:, ["Sample ID", "Features"]]

# Save each table separately
freq_table.to_csv(snakemake.output.frequencies_clean, sep="\t", index=False)
freq_table.to_csv(snakemake.output.frequencies_clean_box, sep="\t", index=False)
features_table.to_csv(snakemake.output.features_clean, sep="\t", index=False)


# ───────────────────────────────
# 3️⃣ Clean stats report
# ───────────────────────────────
stats = pd.read_csv(snakemake.input.stats, sep="\t")

# Drop second row (#q2:types)
stats = stats.drop(0, axis=0).reset_index(drop=True)

stats = stats.rename(
            columns={
                "percentage of input passed filter": "filter_percent",
                "percentage of input merged": "merged_percent",
                "percentage of input non-chimeric": "nonchimeric_percent",
            }
        )

stats.to_csv(snakemake.output.stats_clean, sep="\t", index=False)


# ───────────────────────────────
# 4️⃣ Features summary
# ───────────────────────────────
summary = pd.read_csv(snakemake.input.repseqs_summary, sep="\t")
summary.to_csv(snakemake.output.summary_clean, sep="\t", index=False)
