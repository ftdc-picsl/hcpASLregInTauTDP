#!/bin/bash


idmrlist=$1
bdir=$2

if [[ $# -lt 1 ]] ; then
	echo "./wrap_bbrmanual_cbf_to_t1_pipeline.sh <idmr list>"
	exit 1
fi

if [[ ! -d ${bdir}/ ]] ; then 
	mkdir $bdir
fi

logdir=${bdir}/logs/
if [[ ! -d ${logdir}/ ]] ; then
	mkdir $logdir
fi 

wkdir=/project/ftdc_hcp/aslprep/wrkdir_20220124full/
odir=/project/ftdc_hcp/aslprep/bbrmanual_cbf_to_t1/bbrmanual_cbf_to_t1Output/
scriptsdir=`pwd`
logdir=${odir}/logs/

if [[ ! -d ${logdir} ]] ; then 
	mkdir -p ${logdir}
fi

for idmr in `cat $idmrlist`; do 
	cmd="${scriptsdir}/bbrmanual_cbf_to_t1_pipeline.sh $idmr $wkdir $odir "
 	echo "bsubbing $cmd"
	echo ""
	bsub -J bbrmanual_cbf_to_t1_${idmr} -o ${logdir}/bbrmanual_cbf_to_t1_${idmr}.stdout $cmd
	# $cmd
	sleep .17
done

