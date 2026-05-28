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

Los resultados pueden utilizarse directamente en plataformas como MicrobiomeAnalyst.

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
snakemake --use-conda --cores 4
```

Donde:

* `--use-conda` permite instalar automáticamente todas las dependencias
* `--cores 4` utiliza 4 núcleos del procesador

Si la computadora tiene menos memoria, usar:

```bash
snakemake --use-conda --cores 2
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
