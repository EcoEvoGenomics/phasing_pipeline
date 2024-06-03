#!/usr/bin/env nextflow

// nextflow pipeline for phasing genotype data
// developed by Mark Ravinet - 24/04/2024
// v 0.1 - 24/04/2024
// v 0.2 - 03/06/2024

// simple initial phasing pipeline which will take a vcf or vcfs as input and phase all individuals as a group

// provide a vcf for input
params.vcf = './vcf/sparrows_variants_norm.vcf.gz'
params.map_path = '/cluster/projects/nn10082k/recombination_maps'

// test channel
Channel
    .fromPath("${params.vcf}*") 
    .collect()
    .set{unphased_vcf}

unphased_vcf.view()

// set up windows
windows_list = file(params.windows)
    .readLines()
    //.each { println it }

// make windows channel
Channel
    .fromList( windows_list )
    .set{windows}

// windows.view()
//windows.region.view()
//windows.window.view()
//unphased_vcf.view()

// phase common variants
process phase_common {
    
    errorStrategy 'ignore'
    publishDir 'vcf_phase_window', saveAs: { filename -> "$filename" }

    input:
    path (unphased_vcf)
    each window

    output:
    //path "${window}_phased.bcf"
    tuple \
      path ("${window}_phased.bcf"), \
      path ("${window}_phased.bcf.csi") 

    """
    # create map parameter
    WINDOW=${window}
    echo "This is \${WINDOW} on \${WINDOW%:*}"
    MAP="${params.map_path}/\${WINDOW%:*}.map"

    if [[ -f \${MAP} ]]; then

        echo "\$MAP is present"
        SHAPEIT5_phase_common --input ${unphased_vcf} --region ${window} --map \${MAP} --output ${window}_phased.bcf --thread 12

    else

        echo "\$MAP is not present"
        SHAPEIT5_phase_common --input ${unphased_vcf} --region ${window} --output ${window}_phased.bcf --thread 12

    fi

    """
}

// workflow starts here!
workflow{
    phase_common(unphased_vcf, windows)
}