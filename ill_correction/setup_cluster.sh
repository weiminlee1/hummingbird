#!/bin/bash

##Order, conda, pilon.make, get.data, bt.lib


if [ "$1" == "clean" ]; then
    rm -Rf /shared/install
    rm -Rf /shared/conda
    rm -Rf /shared/nanopolish
fi

if [ "$1" == "conda" ]; then
    cd /shared
    mkdir -p install
    cd /shared/install
    wget https://repo.continuum.io/miniconda/Miniconda3-latest-Linux-x86_64.sh
    ##Suggest install to /shared/conda
    bash Miniconda3-latest-Linux-x86_64.sh -b -p /shared/conda
    
    #echo 'export PATH=/shared/conda/bin:$PATH' >> ~/.bashrc  
fi

if [ "$1" == "get.data" ]; then

    mkdir -p /shared/data
    cd /shared/data
    scp timp@duchess.timplab.com:/atium/Data/NGS/Raw/170901_hbird/wtimp1_139123/FASTQ/HTCV7BCXY_2_0_1.fastq.gz /shared/data/read1.fq.gz
    scp timp@duchess.timplab.com:/atium/Data/NGS/Raw/170901_hbird/wtimp1_139123/FASTQ/HTCV7BCXY_2_0_2.fastq.gz /shared/data/read2.fq.gz
    #rsync -avz -e ssh timp@duchess.timplab.com:/atium/Data/NGS/Raw/170901_hbird/wtimp1_139123/FASTQ/HTCV7BCXY_2_0_* ./
    
    scp timp@duchess.timplab.com:/atium/Data/NGS/Aligned/170901_rubylex_hiseq/cogent_genefam.fa /shared/data/cogent_genefam.fa
    
    
fi


if [ "$1" == "installs" ]; then
    conda install -c bioconda bowtie2 pilon samtools atropos trim-galore
    
    pip install --upgrade atropos
fi

if [ "$1" == "trim.reads" ]; then

    echo "Trimming"

    qsub ~/hummingbird/ill_correction/trim.sh
	    
fi

if [ "$1" == "split.reads" ]; then
    
    echo "Split"
    #split to 1M reads

    cd /shared/data
    gunzip -c trim1.fq.gz | split --additional-suffix=.fq -d -l 4000000 - r1split -a 4
    gunzip -c trim2.fq.gz | split --additional-suffix=.fq -d -l 4000000 - r2split -a 4
    gzip r1split*fq
    gzip r2split*fq

fi


if [ "$1" == "pilon.first.round" ]; then
    
    echo "Pilon"

    ##split fqs
    fqnum=100

    cd /shared/data

    i=1
    ##Make idx
    qsub -N idx${i} -v ref=/shared/data/cogent_genefam.fa ~/hummingbird/ill_correction/idx_maker.sh

    ##align
    qsub -N aln${i} --hold_jid idx${i} -t 1-${fqnum} -v ref=cogent_genefam ~/hummingbird/ill_correction/btalign.sh

    qsub -N pln${i} --hold_jid aln${i} -v ref=cogent_genefam,round=1 ~/hummingbird/ill_correction/pilon.sh
    
    
fi

