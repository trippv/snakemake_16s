# Instalación y ejecución del flujo de trabajo

Este flujo de trabajo utiliza **Snakemake**, **Conda/Mamba** y **QIIME2** para procesar datos de secuenciación 16S rRNA desde lecturas crudas (`FASTQ`) hasta matrices de abundancia y análisis de diversidad.

El pipeline realiza automáticamente:

1. Evaluación de calidad de lecturas crudas (`FastQC` y `MultiQC`)
2. Eliminación de primers y filtrado de calidad con `Cutadapt`
3. Inferencia de variantes ASV mediante `DADA2`
4. Asignación taxonómica utilizando la base de datos SILVA
5. Construcción de árbol filogenético
6. Generación de matrices y archivos compatibles con MicrobiomeAnalyst

---
