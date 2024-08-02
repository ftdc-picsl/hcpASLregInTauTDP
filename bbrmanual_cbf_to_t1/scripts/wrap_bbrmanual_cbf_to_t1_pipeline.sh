#!/bin/bash


idmrlist=$1

if [[ $# -lt 1 ]] ; then
	echo "./wrap_bbrmanual_cbf_to_t1_pipeline.sh <idmr list>"
	echo " this is the wrapper script to submit jobs to the compute cluster to perform the BBR using the manual registrations as initialization"
	echo " it takes a text file with a subject ID per line as imput, loops over them, and submits"
	echo " to set it up: "
	echo "		1) use text editor to edit the wkdir variable to point to the saved working directory of ASLPrep" 
	echo "		2) use text editor to edit the odir variable to point to where you want the output of the manual+BBR pipeline saved. The logs are also saved here" 
	echo "	also, if you don't have a bsub queue system, you may need to modify the submission call" 
	exit 1
fi

# ASLPrep work directory
wkdir=/project/ftdc_hcp/aslprep/wrkdir_20220124full/
# output base directory 
odir=/project/ftdc_hcp/aslprep/bbrmanual_cbf_to_t1/bbrmanual_cbf_to_t1Output/

# bsub log output
logdir=${odir}/logs/
if [[ ! -d ${logdir} ]] ; then 
	mkdir -p ${logdir}
fi

# here 
scriptsdir=`pwd`

for idmr in `cat $idmrlist`; do 
	cmd="${scriptsdir}/bbrmanual_cbf_to_t1_pipeline.sh $idmr $wkdir $odir "
 	echo "bsubbing $cmd"
	echo ""
	bsub -J bbrmanual_cbf_to_t1_${idmr} -o ${logdir}/bbrmanual_cbf_to_t1_${idmr}.stdout $cmd
	# $cmd
	sleep .17
done

