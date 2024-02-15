#!/bin/bash

if [[ $# -lt 2 ]] ; then
	echo "./bbrFlirtcbf_pipeline.sh <idmr> <working directory> <output directory>"
	exit 1
fi

module load fsl/6.0.2
module load ANTs/2.3.5
module load c3d/20191022
module load freesurfer/7.1.1
source /appl/freesurfer-7.1.1/SetUpFreeSurfer.sh
export FSLOUTPUTTYPE=NIFTI_GZ

idmr=$1

wkdir=$2

outdir=$3

manualbasedir=/project/ftdc_hcp/aslprep/reg_fix/
fsdir=/project/ftdc_hcp/pipeline711/

bbroutrt=${outdir}/sub-${idmr}/bbr_out/sub-${idmr}
flirtoutrt=${outdir}/sub-${idmr}/flirt_out/sub-${idmr}

if [[ ! -d ${outdir}/sub-${idmr}/bbr_out/ ]] ; then 
	mkdir -p ${outdir}/sub-${idmr}/bbr_out/
fi
if [[ ! -f ${outdir}/sub-${idmr}/flirt_out/ ]] ; then 
	mkdir -p ${outdir}/sub-${idmr}/flirt_out/
fi

# inimg="${wkdir}/aslprep_wf/single_subject_${idmr}_wf/asl_preproc_acq_pcasl_wf/asl_reference_wf/enhance_and_skullstrip_asl_wf/apply_mask/uni_xform_masked.nii.gz"
inimg="${wkdir}/aslprep_wf/single_subject_${idmr}_wf/asl_preproc_acq_pcasl_wf/compt_cbf_wf/computecbf/sub-${idmr}_acq-pcasl_asl_cbftimeseries_meancbf.nii.gz"

t1brainmgz=${fsdir}/${idmr}/mri/brain.mgz 
t1brainnii=${fsdir}/${idmr}/mri/brain.nii.gz

if [[ ! -f ${t1brainnii} ]] ; then
	cmd="mri_convert ${t1brainmgz} ${t1brainnii}"
	echo $cmd 
	$cmd
	echo ""
fi

t1ref=${fsdir}/${idmr}/mri/T1-converted.nii.gz

wmmgz=${fsdir}/${idmr}/mri/wm.seg.mgz 
wmnii=${fsdir}/${idmr}/mri/wm.seg.nii.gz
wmmask=${outdir}/sub-${idmr}/bbr_out/sub-${idmr}_wm_seg_mask.nii.gz

if [[ ! -f ${wmnii} ]] ; then
	cmd="mri_convert ${wmmgz} ${wmnii}"
	echo $cmd 
	$cmd
	echo ""
fi

if [[ ! -f ${wmmask} ]] ; then
	cmd="c3d ${wmnii} -thresh 1 Inf 1 0 -o ${wmmask}"
      	echo $cmd
	$cmd
	echo ""	
fi

function check_in () {
	if [[ ! -f $1 ]] ; then
		echo "no image $1 ... exiting"
		exit 1
        fi
}

check_in ${inimg}
check_in ${wmmask}
check_in ${t1ref}
check_in ${t1brainnii}

flirtmat=${flirtoutrt}_asl_to_t1_flirt.mat

# perform flirt using different images but same parameters as aslprep
cmd="flirt -in ${inimg} -ref ${t1brainnii} -out ${flirtoutrt}_asl_to_t1_flirt.nii.gz -omat ${flirtmat} -dof 6 -usesqform"
echo $cmd 
$cmd
echo ""

# dont need conversion...?  
# flirtdat=${flirtoutrt}_asl_to_t1_flirt.dat

# convert the freesurfer dat to fsl mat
# lta_convert --inreg ${dat} --outfsl ${manualmat} --src ${inimg} --trg ${t1ref}

bbrflirtmat=${bbroutrt}_asl_to_t1_flirt_plusbbr.mat
cmd="flirt -in ${inimg} -ref ${t1brainnii} -init ${flirtmat} -wmseg ${wmmask} -out ${bbroutrt}.nii.gz -omat ${bbrflirtmat} -dof 6 -usesqform -cost bbr " 

echo $cmd 
$cmd
echo ""

# create inverse because it's done 
invbbrflirtmat=${bbroutrt}_asl_to_t1_flirt_plusbbr_inv.mat
cmd="convert_xfm -omat ${invbbrflirtmat} -inverse ${bbrflirtmat}"
echo $cmd
$cmd

# itk the mats
c3d_affine_tool -ref ${t1ref} -src ${inimg} ${bbrflirtmat} -fsl2ras -oitk ${bbroutrt}_asl_to_t1_flirt_plusbbr.txt

c3d_affine_tool -ref ${inimg} -src ${t1ref} ${invbbrflirtmat} -fsl2ras -oitk ${bbroutrt}_asl_to_t1_flirt_plusbbr_inv.txt


CreateTiledMosaic -i ${t1ref} -e [${bbroutrt}.nii.gz,/project/ftdc_hcp/aslprep/bbrManual/bbrManualcbfOutput/sub-${idmr}/bbr_out/sub-${idmr}fastmask.nii.gz] -a .5 -t 7x7 -s [4,65,265] -o ${bbroutrt}_flirt_bbr_on_t1-converted.png 
