# Phasing pipeline

### Mark Ravinet 
### 06/05/2024

## Introduction

Welcome to the readme and userguide for the Evolutionary and Ecological Genetics Group **statistical phasing pipeline**. This is a simple nextflow workflow management script that will quickly and efficiently phase variants across genome windows. A second script will then concatenate these windows into full phased, per chromosome vcfa, 

As with our [variant calling pipeline](https://github.com/markravinet/genotyping_pipeline), the scripts are designed to be used with minimal. The idea is once again to simplify the process of the busy work of population genomics to allow end-users to focus more on the interesting analyses a phased dataset might provide - i.e. haplotype based selective sweep statistics or ancestry analyses.

That does not mean this pipeline should be used as a [black box](https://en.wikipedia.org/wiki/Black_box). It is well worth learning a bit about [how statistical phasing works](https://en.wikipedia.org/wiki/Haplotype_estimation) and the way [you might run it *without* this pipeline](https://speciationgenomics.github.io/phasing/).

The pipeline operates with two scripts - `phasing.nf` and `ligate.nf`. These are based on [shapeit5](https://odelaneau.github.io/shapeit5/) a fast, [accurate and efficient phasing program for large datasets](https://www.nature.com/articles/s41588-023-01415-w). This readme also includes an example script (`run_phasing_pipeline_saga.slurm`) for running the pipeline on the Sigma2 Saga supercomputer in Norway. 

**NB The pipeline is designed to work alongside our [variant calling pipeline](https://github.com/markravinet/genotyping_pipeline)**. However, in principle it should work with out issue with any variant set called by other means. If you have installed and ran the variant calling pipeline, you can skip the majority of these installation instructions with the exception of **`configuring the conda environment`**

## Installation

The simplest way to install everything you need for these scripts to work is to use template `conda` environment. This means you first need to install and setup `conda`. 

### Installing conda

The full `conda` installation is not necessary. Instead you can use miniconda. Go here and copy the link address for the latest release for Linux 64-bit. Then use `wget` to download it like so:

```
wget https://repo.anaconda.com/miniconda/Miniconda3-latest-Linux-x86_64.sh
```

From your home directory, simply run this script:

```
bash Miniconda3-latest-Linux-x86_64.sh
```

Follow the prompts and this will install `conda`. Once you have done that, you will need to update it to ensure there are no issues.

```
conda update conda
```

We are then read to set up the `conda` environment you need to run the scripts.

### Using mamba

Conda can be quite slow, so a way to speed it up is to use `mamba`. This is easy to install. You can do so like this:

```
conda install -c conda-forge mamba
```

Once `mamba` is installed you are ready to configure the `conda` environment to use the pipeline.

### Configuring the conda environment

In order to ensure you have all the tools needed to run the pipeline, you can configure the `conda` environment using the `phasing.yml` provided here. This is also a reference of all the software versions used to run the code. It is very simple to do this, just use the following command:

```
mamba env create --name phase -f phasing.yml 
```

This will create a `mamba`/`conda` environment called `phase` that contains all the software necessary to run the scripts with minimal manual configuration. 

## Running the pipeline

The pipeline is quite simple. First it performs statistical phasing in windows across the genome. To do this, it needs a configuration of windows that it should split the genome into (see below) - I typically use 10Mb windows.

The pipeline is very simple to run. You should set it up to run in a single working directory. You then run it like so:

```
nextflow run phasing.nf --vcf 'path/to/variant.vcf.gz --windows genome_windows.list --map_path /path/to/map'
```

The script takes three simple arguments that you have to provide:

`--vcf` - a path to a vcf file. This should be a full vcf of all genome regions (i.e. chromosomes) concatenated together.
`--windows` - a file of detailing the genome windows which the phasing should operate on. See instructions for the [variant calling pipeline to learn how to generate this file](https://github.com/markravinet/genotyping_pipeline).
`--map_path` - a path to a directory of recombination maps for the genome, with one file per chromosome you are running the pipeline on.

All of these options are necessary for the script to run. However, if you are running the script on `saga` and you are using it on the house sparrow genome, you can ommit the `--map_path` argument as this is coded in (see below for more info on map files). 

The `phasing.nf` script will output the phased windows in a directory called `vcf_phase_window`
After this you can use the `ligate.nf` script to combine these into single per chromsome vcfs. This is very simple to do:

```
nextflow run ligate.nf
```

The script needs no other options and will look for all the phased output in `vcf_phase_window` in order to run.

### Genome windows

As above, see here for information on how to create these. If there is no map available (i.e. sex chromosome or scaffolds), the pipeline will skip the need for this file. 

It is also worth noting that **there is not much point in phasing the scaffolds**, so you can delete these from the genome windows file to stop it running on them. 

### Map files

On `saga`, map files are stored in the shared group directory - `/cluster/projects/nn10082k/recombination_maps`

These files are simply recombination rate maps for each of the autosomes - i.e. the genome position, the recombination rate and genetic map distance (in centiMorgans). 

### Script outputs

Once complete the script will create a directory called `vcf_phased`. This will contain two files for each chromosome - here we use `chr1` as an example:

- `chr1_phased.bcf`
- `chr1_phased.bcf.csi`

These are simply binary compress vcfs (i.e. bcfs) and their indexes. If you wish to convert them back to vcf use the following command:

```
bcftools view -O z -o chr1_phased.vcf.gz chr1_phased.bcf
```

This will take sometime, so best do it in a slurm script. 

Overall the phased vcfs are smaller as they have had a lot of site information stripped and they are formatted slightly differently. See [here](https
://speciationgenomics.github.io/phasing/) for a deeper explanation of working with phased data and expoloring a phased vcf.

## Submitting the nextflow pipeline via slurm

The nextflow scripts will take care of the individual scheduling of jobs, but you will need to submit a management job to the cluster using a standard slurm script. This script should be set to run with a relatively low memory (i.e. 4-8Gb), a single CPU and a relatively long time for the entire pipeline to run. For example, you could run it for a week. 

The actual control for each of the different jobs that the nextflow pipeline submits, you should look at the `nextflow.config` file - this is different to the one for the variant calling pipeline and is built especially for this one. The config file is already to set up to use slurm. However, slurm job schedulers will differ between institutions. So be sure to double check this.

**NB if you want to test the pipeline locally** you need to change the name of the `nextflow.config` file so that it is not read by the pipeline automatically. For example, just do this:

```
mv nextflow.config nextflow_config
```

Just remember that when you do go back to submitting the nextflow script, you must change this back so that the pipeline will resume the slurm execution. 
