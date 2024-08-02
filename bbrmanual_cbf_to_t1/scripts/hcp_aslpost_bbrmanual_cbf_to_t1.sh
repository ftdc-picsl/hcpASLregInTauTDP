#!/bin/bash

if [[ $# -lt 7 ]] ; then 
	echo "USAGE: ./hcp_aslpost.sh <sub> <aslprep dir> <aslprep wrk dir> <freesurfer dir>  <aslpost output dir> <scriptsdir> <bidsdir>"
	echo " script for removing any clipped voxels and out-of-bounding-box voxels removed from CBF calculation" 
	echo "     sub is id part sub-id "
	echo "	   aslprep dir is base aslprep output directory. Needed for t1 reference images"
	echo "     aslprep wrk dir is working directory. Needed for asl-to-t1 affine.mat "
	echo "     freesurfer dir is SUBJECTS_DIR"
	echo "     aslpost output dir is base directory for where output will go"
	echo "	   scripts dir is home to scripts "
	echo "	   bidsdir is directory with bids data"
 	exit 1
fi



sub=$1
aslprepdir=$2
aslprepwrkdir=$3
freesurferdir=$4
aslpostdir=$5
# aslfiletag=$6 
scriptsdir=$6
bidsdir=$7

module load R/4.0

module load freesurfer/7.1.1
source /appl/freesurfer-7.1.1/SetUpFreeSurfer.sh

newregdir=/project/ftdc_hcp/aslprep/bbrmanual_cbf_to_t1/bbrmanual_cbf_to_t1Output/sub-${sub}/bbr_out/
aslpostdir=${aslpostdir}/sub-${sub}/aslpost_bbr_out/

if [[ ! -d ${aslpostdir} ]] ; then
	mkdir -p ${aslpostdir}
fi

# check images exist
affmat=${newregdir}/sub-${sub}_cbf_to_t1_affine_manual_plusbbr.mat
affdat=${newregdir}/sub-${sub}_cbf_to_t1_affine_manual_plusbbr.dat
aslref="${aslprepwrkdir}/aslprep_wf/single_subject_${sub}_wf/asl_preproc_acq_pcasl_wf/compt_cbf_wf/computecbf/sub-${sub}_acq-pcasl_asl_cbftimeseries_meancbf.nii.gz"

echo $aslref

if [[ ! -f ${aslref} ]] ; then 
	echo "no aslref image...exiting"
	exit 1
fi

# if we need a .dat transform file, create it
if [[ ! -f ${affdat} ]] ; then 
	echo "creating ${affdat} ... " 
	cmd="${scriptsdir}/dat_the_mat.sh ${sub} ${affmat} ${affdat} ${freesurferdir} ${aslref}"
	echo $cmd 
	$cmd
	echo "" 
else
	echo "${affdat} exists...skipping dat_the_mat.sh" 
fi

# find clipped voxels in raw image 
aslim=`ls ${bidsdir}/sub-${sub}/perf/sub-${sub}_*asl.nii.gz`
clipheatrt=${aslpostdir}/sub-${sub}
if [[ ! -f ${aslim} ]] ; then
	echo "no asl image found for ${sub}"
	echo "...exiting"
	exit 1
fi

echo ""
cmd="${scriptsdir}/notsogreatclips.R ${sub} ${aslim} ${clipheatrt}"
echo ${cmd}
${cmd}
echo ""

# get clipped mask into T1 space to censor images
clipfiletag=asl4095heatmap
aslclips=${aslpostdir}/sub-${sub}_asl4095heatmap.nii.gz

cmd="${scriptsdir}/asl_to_t1.sh ${sub} ${affdat} ${aslclips} ${freesurferdir} ${aslpostdir} ${clipfiletag} "
echo ${cmd}
${cmd}
echo "" 

if [[ ! -f ${aslclips} ]] ; then 
	echo "no aslclip image ${aslclips} for sub ${sub}...exiting"
	exit 1
fi

# loop over aslprep outputs
# 1) transform them into t1 space
# 2) remove the clipped out voxels from the ROIs and re-compute the means  
# for aslfiletag in acq-pcasl_desc-basil_cbf acq-pcasl_desc-pvGM_cbf acq-pcasl_desc-score_mean_cbf acq-pcasl_desc-scrub_cbf acq-pcasl_mean_cbf ; do
for aslfiletag in acq-pcasl_mean_cbf; do
	echo ""
	movingimg=${aslprepdir}/aslprep/sub-${sub}/perf/sub-${sub}_${aslfiletag}.nii.gz
	if [[ ! -f ${movingimg} ]] ; then 
		echo "no image ${movingimg} for ${sub}...skipping"
	else
		cmd="${scriptsdir}/asl_to_t1.sh ${sub} ${affdat} ${movingimg} ${freesurferdir} ${aslpostdir} ${aslfiletag}bbrmanual_cbf_to_t1"
		echo ${cmd}
		${cmd}
		echo "" 

		echo ""
		for lscale in 36 60 125 250; do 
			cmd="${scriptsdir}/clipTheAnnotRemoveThe0s.R ${sub} ${lscale} ${aslfiletag}bbrmanual_cbf_to_t1 ${aslpostdir} ${freesurferdir}"
			echo ${cmd}
			${cmd}
			echo ""
		done
	fi

done

echo ""
