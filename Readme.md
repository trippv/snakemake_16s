# snakemake_16s

Pipeline reproducible en Snakemake para análisis de secuencias 16S usando QIIME2.

El flujo realiza:

1. Evaluación de calidad de lecturas crudas (`FastQC`)
2. Eliminación de primers y lecturas de baja calidad (`Cutadapt`)
3. Inferencia de ASVs (`DADA2`)
4. Asignación taxonómica usando `SILVA`
5. Generación de:

   * matrices de abundancia
   * taxonomía
   * árbol filogenético

Los resultados pueden utilizarse directamente en plataformas como [MicrobiomeAnalyst](https://www.microbiomeanalyst.ca/).

---

# Instalación

## 1. Instalar Miniforge (recomendado)

Este pipeline utiliza `mamba`, un administrador de ambientes rápido y compatible con `conda`.

### Linux (Ubuntu, WSL, Chromebook Linux)

Abrir una terminal y ejecutar:

```bash
wget https://github.com/conda-forge/miniforge/releases/latest/download/Miniforge3-Linux-x86_64.sh

bash Miniforge3-Linux-x86_64.sh
```

Durante la instalación:

* presionar `ENTER` para continuar
* escribir `yes` cuando lo solicite

Al finalizar, cerrar y volver a abrir la terminal.

Verificar instalación:

```bash
mamba --version
```

---

# 2. Instalar Snakemake

Crear un ambiente para Snakemake:

```bash
mamba create -n snakemake snakemake -c conda-forge -c bioconda
```

Activar el ambiente:

```bash
mamba activate snakemake
```

Verificar instalación:

```bash
snakemake --version
```

---

# 3. Descargar el pipeline

Clonar el repositorio:

```bash
git clone https://github.com/trippv/snakemake_16s.git
```

Entrar al directorio:

```bash
cd snakemake_16s
```

---

# 4. Ejecutar el pipeline

Activar el ambiente de Snakemake:

```bash
mamba activate snakemake
```

Ejecutar el workflow:

```bash
snakemake --use-conda --cores 8
```

Donde:

* `--use-conda` permite instalar automáticamente todas las dependencias
* `--cores 8` utiliza 8 núcleos del procesador

Si la computadora tiene menos memoria, usar:

```bash
snakemake --use-conda --cores 4
```

La primera ejecución puede tardar bastante tiempo porque Snakemake instalará automáticamente todos los programas necesarios.

---

# Estructura general del proyecto

```text
snakemake_16s/
├── config/
├── envs/
├── rules/
├── scripts/
├── results/
├── Snakefile

```

---

## Configuración

Antes de ejecutar el flujo de trabajo, es necesario preparar los archivos de configuración ubicados en la carpeta `config/`.

---

## 1. Archivo de muestras (`samples_files.tsv`)

Este archivo contiene la ubicación de los archivos FASTQ crudos para cada muestra.

El archivo **debe estar separado por tabuladores (`.tsv`)** y contener las siguientes columnas:

* `sample_id`
* `forward-absolute-filepath`
* `reverse-absolute-filepath`
* `file_extension`

Ejemplo:

```tsv id="44yhgn"
sample_id	forward-absolute-filepath	reverse-absolute-filepath	file_extension
N43	/home/user/project/rawreads/N43_R1.fastq.gz	/home/user/project/rawreads/N43_R2.fastq.gz	gz
N47	/home/user/project/rawreads/N47_R1.fastq.gz	/home/user/project/rawreads/N47_R2.fastq.gz	gz
R58	/home/user/project/rawreads/R58_R1.fastq.gz	/home/user/project/rawreads/R58_R2.fastq.gz	gz
```

### Notas importantes

* Las rutas de los archivos deben ser rutas absolutas.
* Los archivos forward y reverse deben corresponder a la misma muestra.
* Las extensiones soportadas incluyen:

  * `gz`
  * `fastq`
  * `fq`

---

## 2. Archivo de metadatos (`sample_metadata.tsv`)

Este archivo contiene la información asociada a cada muestra y será utilizado en los análisis de diversidad y visualización.

El archivo **debe estar separado por tabuladores (`.tsv`)**.

La primera columna debe contener los identificadores de muestra que coincidan con la columna `sample_id` del archivo `samples_files.tsv`.

Ejemplo:

```tsv id="ps02z7"
SampleID	index_1	index_2	SampleType	Species	S_index	N_index	project	Location	group	Run	Longitud_CM	No Organismo	Sexo	Tejido	Tipo muestra	Fecha Colecta	Fecha muestra tejido	observaciones tejido
Y49	TAGGCATG	AAGGAGTA	gut	Sphyrna lewini	S507	N706	16s	Santa Rosalia	Sphyrna lewini-Santa Rosalia	Run27	80	3	hembra	Estomago	Raspado epitelio	29/10/21	23/05/2023	Muy poco materia. Los pliegues eran muy visibles
Y47	GGACTCCT	AAGGAGTA	gut	Sphyrna lewini	S507	N705	16s	Santa Rosalia	Sphyrna lewini-Santa Rosalia	Run27	79	2	hembra	Estomago	Raspado epitelio	29/10/21	23/05/2023	lleno de materia organica con algunas vertebras y restos duros
Y41	TCCTGAGC	AAGGAGTA	gut	Sphyrna lewini	S507	N704	16s	Santa Rosalia	Sphyrna lewini-Santa Rosalia	Run27	74	7	hembra	Estomago	Raspado epitelio	28/09/2021	17/05/2023	Mucha materia organica y fragmentos de vertebras
```

### Notas importantes

* Los nombres de las muestras deben coincidir entre:

  * `samples_files.tsv`
  * `sample_metadata.tsv`
* Se pueden agregar columnas adicionales libremente.
* Evita usar espacios o caracteres especiales en los IDs de muestra.

---




Archivo de configuración (config/config.yaml)

El flujo de trabajo se controla mediante el archivo:

config/config.yaml

En este archivo se definen:

    *   El nombre de la corrida
    *   Los archivos de entrada
    *   Parámetros de calidad y filtrado
    *   Configuración de cutadapt
    *   Parámetros de DADA2
    *   Opciones de filtrado de ASVs
    *   Base de datos taxonómica utilizada

Ejemplo básico:
```
# Nombre de la corrida
run_name: "run_prueba"

# Archivo con las rutas de los FASTQ
samples_file: "config/samples_files_test.tsv"

# Metadata de las muestras
metadata: "config/sample_metadata_test.tsv"
```


# Ejecutar el workflow por etapas (checkpoints)

El flujo de trabajo incluye varios **checkpoints** que permiten revisar la calidad y el progreso del análisis antes de continuar con los siguientes pasos.

Esto es útil para:

* Detectar problemas tempranamente
* Ajustar parámetros si es necesario
* Revisar reportes de calidad
* Evitar perder tiempo ejecutando todo el pipeline

Snakemake permite ejecutar el workflow **hasta un checkpoint específico** usando la opción:

```bash
snakemake --use-conda --cores 4 --until NOMBRE_DEL_CHECKPOINT
```

---

# Checkpoint 1: Control de calidad inicial

## ¿Qué hace?

Este checkpoint ejecuta:

* `FastQC` → evaluación de calidad de lecturas crudas
* `Cutadapt` → eliminación de primers/adaptadores y lecturas cortas
* `MultiQC` → generación de reportes resumidos

## Ejecutar

```bash
snakemake --use-conda --cores 4 --until checkpoint_pre_import
```

## Archivos generados

Los reportes se guardan en:

```bash
results/<run_name>/checkpoint/
```

Archivos principales:

* `checkpoint_fastqc.html`
* `checkpoint_cutadapt.html`

## ¿Qué revisar?

* Calidad general de las lecturas
* Presencia de adaptadores
* Longitud de las secuencias
* Número de lecturas retenidas después de Cutadapt

---

# Checkpoint 2: Resultados de DADA2

## ¿Qué hace?

Este checkpoint ejecuta:

* Detección de ASVs con `DADA2`
* Filtrado de quimeras
* Generación de tablas limpias
* Reporte resumido con `MultiQC`

## Ejecutar

```bash
snakemake --use-conda --cores 4 --until checkpoint_dada2
```

## ¿Qué revisar?

* Número de lecturas retenidas
* Tasa de filtrado
* Número de ASVs detectados
* Pérdida de muestras

## Archivo generado

```bash
results/<run_name>/checkpoint/dada2_qc_report.html
```

---

# Checkpoint 3: Curvas de rarefacción

## ¿Qué hace?

Genera curvas de rarefacción para evaluar si la profundidad de secuenciación fue suficiente.

## Ejecutar

```bash
snakemake --use-conda --cores 4 --until alpha_rarefaction_curve
```

## Archivo generado

```bash
results/<run_name>/checkpoint/alpha_rarefaction_exported/alpha_rarefaction.html
```

## ¿Qué revisar?

* Si las curvas alcanzan una meseta
* Si la profundidad seleccionada es adecuada
* Comparación de riqueza entre muestras

---

# Ejecutar todo el workflow

Para ejecutar el pipeline completo:

```bash
snakemake --use-conda --cores 4
```

Puedes cambiar el número de núcleos (`--cores`) dependiendo de tu computadora.
