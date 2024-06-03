#!/usr/bin/env nextflow

// nextflow pipeline for phasing genotype data
// ligation script
// developed by Mark Ravinet - 24/04/2024
// v 0.1 - 24/04/2024

// simple initial phasing pipeline which will take a vcf or vcfs as input and phase all individuals as a group

// provide a vcf for input
Channel
    .fromPath( './vcf_phase_window/*.bcf*' )
    .map { file ->
        def key = file.baseName.toString().tokenize(':').get(0)
        return tuple(key, file)
      }
    .groupTuple( by:0,sort:true )
    .set{phased_vcf_windows}

phased_vcf_windows.view()

// ligate phased vcfs - nb this must be done WITHIN chromosomes - it cannot be done across the entire genome
process ligate_chr {

    // publish simlinks into a final vcf directory
    publishDir 'vcf_phased', saveAs: { filename -> "$filename" }, mode: 'copy'

    input:
    tuple val(key), file(vcfs)

    output:
    tuple \
      file ("${key}_phased.bcf"), \
      file ("${key}_phased.bcf.csi") 

    """
    # sort vcfs (and remove indexes)
    sort_vcfs=\$(echo ${vcfs} | tr ' ' '\n' |  grep -v ".csi" | sort -t"-" -k2 -n | tr '\n' ' ')

    # create ligate file
    for i in \$sort_vcfs; do echo \$i >> chunks.txt ; done

    # ligate and produce bcf
    SHAPEIT5_ligate --input chunks.txt --output ${key}_phased.bcf --index --thread 12
    """
}

// workflow starts here!
workflow{
    ligate_chr(phased_vcf_windows) | view
}
