#!/bin/bash

if [[ $# -lt 2 ]] ; then
	echo "./bbrmanual_cbf_to_t1_pipeline.sh <idmr> <working directory> <output directory>"
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

manualbasedir=/project/ftdc_hcp/aslprep/manual_cbf_to_t1/
fsdir=/project/ftdc_hcp/pipeline711/

outrt=${outdir}/sub-${idmr}/bbr_out/sub-${idmr}

if [[ ! -d ${outdir}/sub-${idmr}/bbr_out/ ]] ; then 
	mkdir -p ${outdir}/sub-${idmr}/bbr_out/
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

# get the manual matrix as initialization to bbr 
manualdat=${manualbasedir}/sub-${idmr}/sub-${idmr}_cbf_to_t1_affine.dat

manualmat=${outrt}_cbf_to_t1_affine_manual.mat

# convert the freesurfer dat to fsl mat
lta_convert --inreg ${manualdat} --outfsl ${manualmat} --src ${inimg} --trg ${t1ref}

cmd="flirt -in ${inimg} -ref ${t1brainnii} -init ${manualmat} -wmseg ${wmmask} -out ${outrt}.nii.gz -omat ${outrt}_cbf_to_t1_affine_manual_plusbbr.mat -dof 6 -usesqform -cost bbr " 

echo $cmd 
$cmd
echo ""

# create inverse because it's done 

cmd="convert_xfm -omat ${outrt}_cbf_to_t1_affine_manual_plusbbr_inv.mat -inverse ${outrt}_cbf_to_t1_affine_manual_plusbbr.mat"
echo $cmd
$cmd

# itk the mats

c3d_affine_tool -ref ${t1ref} -src ${inimg} ${outrt}_cbf_to_t1_affine_manual_plusbbr.mat -fsl2ras -oitk ${outrt}_cbf_to_t1_affine_manual_plusbbr.txt

c3d_affine_tool -ref ${inimg} -src ${t1ref} ${outrt}_cbf_to_t1_affine_manual_plusbbr_inv.mat -fsl2ras -oitk ${outrt}_cbf_to_t1_affine_manual_plusbbr_inv.txt


CreateTiledMosaic -i ${t1ref} -r ${outrt}.nii.gz -a .3 -t 7x7 -s [4,65,265] -o ${outrt}_cbf_manual_bbr_on_t1-converted.png 
