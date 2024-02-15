#!/bin/bash


idmrlist=$1

if [[ $# -lt 1 ]] ; then
	echo "./wrap_bbrFlirtcbf_pipeline.sh <idmr list>"
	exit 1
fi

wkdir=/project/ftdc_hcp/aslprep/wrkdir_20220124full/
odir=/project/ftdc_hcp/aslprep/bbrFlirt/bbrFlirtcbfOutput/
scriptsdir=`pwd`
logdir=${odir}/logs/

if [[ ! -d ${logdir} ]] ; then 
	mkdir -p ${logdir}
fi

for idmr in `cat $idmrlist`; do 
	cmd="${scriptsdir}/bbrFlirtcbf_pipeline.sh $idmr $wkdir $odir "
	echo "bsubbing $cmd"
	echo ""
	bsub -J bbrFlirtcbf_${idmr} -o ${logdir}/bbrFlirtcbf_${idmr}.stdout $cmd
	sleep .17
done

