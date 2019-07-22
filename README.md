# ARDaP - Antimicrobial Resistance Detection and Prediction

ARDaP was written by Derek Sarovich ([@DerekSarovich](https://twitter.com/DerekSarovich)), Eike Steinig and Erin Price ([@Dr_ErinPrice](https://twitter.com/Dr_ErinPrice)) at University of the Sunshine Coast, Queensland, Australia.
## Contents

- [Introduction](#introduction)
- [Installation](#Installation)
- [Resource Managers](#resource-managers)
- [SPANDx Workflow](#spandx-workflow)
- [Usage](#usage)
- [Parameters](#parameters)
- [Important Information](#important-information)
- [GWAS and SPANDx](gWAS-and-spandx)
- [Citation](#citation)


## Introduction

ARDaP (Antimicrobial Resistance Detection and Prediction) is a genomics pipeline 
for the comprehensive identification of antibiotic resistance markers from whole-genome
sequencing data. The impetus behind the creation of ARDaP was our frustration 
with current methodology not being able to detect antimicrobial resistance when confered by "complex" mechanisms.
Our two species of interest, <i>Burkholderia pseudomallei</i> and <i>Pseudomonas aeruginosa</i>, develop antimicrobial resistance
in a multiple ways but predominately through chromosomal mutations, including gene loss, copy number variation, single nucleotide polymorphisms and indels. ARDaP will first identify all genetic variation in a sample and then interrogate this information against a user created database of resistance mechanisms. The software will then summarise the identified mechanisms and produce a simple report for the user.


## Installation

**Github**

1) Download the latest installation with git clone

```
https://github.com/dsarov/ARDaP.git
```

2) Install the nextflow pipeline manager if not already installed

More information about nextflow can be found here --> https://www.nextflow.io/docs/latest/getstarted.html
```
wget -qO- https://get.nextflow.io | bash
```
3) Change into the ARDaP directory and activate/install the conda environment

```
cd ARDaP

```

**Optional for GWAS** 



## Resource Managers

ARDaP is mostly written in the nextflow language and as such has support for most common resource management systems.

//Need to include information about how to activate different schedulers

## ARDaP Workflow

To achieve high-quality variant calls, ARDaP incorporates the following programs into its workflow:

- Burrows Wheeler Aligner (BWA)
- SAMTools
- Picard
- Genome Analysis Toolkit (GATK)
- BEDTools
- SNPEff
- VCFtools

## Usage

```bash
SPANDx.sh -r REFERENCE
```
## Parameters

    Required Parameters:
      -r            reference, without .fasta extension
      
    Optional Parameters:
      -o            Organism name
      -m            Generate SNP matrix - yes/no  
      -i            Generate indel matrix - yes/no 
      -a	        Include annotation - yes/no
      -v            Variant genome file - Name must match the SnpEff database 
      -s            Specify read prefix to run single strain 
      -t            Sequencing technology used Illumina/Illumina_old/454/PGM (default: Illumina)
      -p            Pairing of reads - PE/SE (default: PE)
      -w            Window size in base pairs for BEDcoverage module (default: 1000)
      -z            Include tri- and tetra-allelic SNPs in the SNP matrix - yes/no

## Important Information

### File names
SPANDx, by default, expects reads to be paired-end, Illumina data in the following format: 

```
STRAIN_1_sequence.fastq.gz (first pair) 
STRAIN_2_sequence.fastq.gz (second pair)
```
Reads not in this format will be ignored. If your data are not paired, you must set the -p parameter to SE to denote unpaired reads.

### SPANDx requires a reference file in FASTA format

For compatibility with all steps in SPANDx, FASTA files should conform to the specifications [listed here](http://www.ncbi.nlm.nih.gov/BLAST/blastcgihelp.shtml). Note that the use of nucleotides other than A, C, G, or T is not supported by certain programs in SPANDx so should not be used in reference FASTA files. In addition, Picard, GATK and SAMtools handle spaces within contig names differently. Therefore, please do not use spaces or special characters (e.g. $/*) in contig names.

By default, all reads in SPANDx format (i.e. strain_1_sequence.fastq.gz) in the present working directory are processed. Sequence files are aligned against the reference using BWA. Alignments are subsequently filtered and converted using SAMtools and Picard Tools. SNPs and indels are identified with GATK and coverage assessed with BEDtools. 


### Variant Identification

All variants identified in the single genome analysis are merged and re-verified across the entire dataset to minimise incorrect variant calls. This error-correction step is an attempt at establishing a "Best Practice" guideline for datasets where variant recalibration is not yet possible due to a lack of comprehensive quality-assessed variants (i.e. most haploid datasets!). Such datasets are available for certain eukaryotic species (e.g. human, mouse), as detailed in GATK "Best Practice" guidelines.

Finally, SPANDx merges high-quality, re-verified SNP and indel variants into user-friendly .nex matrices, which can be used for phylogenetic resconstruction using various phylogenetics tools (e.g. PAUP, PHYLIP, RAxML).

## GWAS and SPANDx

The main comparative outputs of SPANDx (SNP matrix, indel matrix, presence/absence matrix, annotated SNP matrix and annotated indel matrix in $PWD/Outputs/Comparative/) can be used as input files for mGWAS. From version 2.6 onwards, SPANDx is distributed with GeneratePlink&#46;sh. The GeneratePlink&#46;sh script requires two input files: an ingroup.txt file and an outgroup.txt file. The ingroup.txt file should contain a list of the taxa of interest (e.g. antibiotic-resistant strains) and the outgroup.txt file should contain a list of all taxa lacking the genotype or phenotype of interest (e.g. antibiotic-sensitive strains). The ingroup.txt and outgroup.txt files must include only one strain per line. Although larger taxon numbers in the ingroup and outgroup files will increase the statistical power of mGWAS, it is better to only include relevant taxa i.e. do not include taxa that have not yet been characterised, or that have equivocal data. The GeneratePlink&#46;sh script will generate .ped and .map files for SNPs, and presence/absence loci and indels if these were identified in the initial analyses. The .ped and .map files can be directly imported into PLINK. For more information on mGWAS and how to run PLINK, please refer to the [PLINK website](http://pngu.mgh.harvard.edu/~purcell/plink/)

### GeneratePLINK usage:

```bash 
GeneratePLINK.sh -i ingroup.txt -o outgroup.txt -r reference (without .fasta extension)
```
Comparing microbial genomes with the above methods will test for associations with orthologous and non-orthologous SNPs, indels and a presence/absence analysis. For more thorough mGWAS the accessory genome also needs to be taken into account and is a non-trivial matter in microbes due to the presence of multiple paralogs. To accurately characterise the accessory genome an accurate pan-genome is required. To construct a pan-genome we recommend the excellent pan-genome software, [Roary](https://sanger-pathogens.github.io/Roary/). Once a pan-genome has been created the script GeneratePLINK_Roary.sh can be used to analyse associations between the groups of interest. GeneratePLINK_Roary&#46;sh is run similarly to GeneratePLINK.sh and requires both an ingroup.txt file and an outgroup.txt file. Once this script has been run the .ped and .map files should be directly importable into PLINK.

### GeneratePLINK_Roary.sh usage

```bash
GeneratePLINK_Roary.sh -i ingroup.txt -o outgroup.txt -r Roary.csv output (if different than the default gene_presence_absence.csv)
```
**Note that this script has an additional requirement for R and Rscript with the dplyr package installed. If this script can’t find these programs in your path then it will fail**

## Citation

Sarovich DS & Price EP. 2014. SPANDx: a genomics pipeline for comparative analysis of large haploid whole genome re-sequencing datasets. <i>BMC Res Notes</i> 7:618.

Please send bug reports to derek.sarovich@gmail.com.
