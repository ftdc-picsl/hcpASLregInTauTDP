#!/bin/bash

if [[ $# -lt 1 ]] ; then 
  echo "USAGE: ./wrap_hcp_aslpost_bbrFlirtcbf.sh <list of sub ids>  "
  echo " does all aslpost-processing" 
  echo "	1) get CBF images into T1 and fsaverage surface spaces"
  echo "	2) identify clipped voxels "
  echo " 	3) remove clipped voxels from ROI stats "
  echo "           sub ids are the sub-{id} of the participants to pull the icv from" 
  echo "           sub ids must be presnt in the {ASLPrep output directory}"
  echo "           sub ids can be plain or begin with sub-" 
  echo "           sub ids can optionally also be a csv with ses- ids as the second field per line, but independently processed structural scans from different sessions from same subject do not seem supported by ASLPrep currently (3/15/21)" 
  echo "           "
  echo " use text editor to specify aslprep output directory, aslprep working directory, freesurfer SUBJECTS_DIR, as well as output directory for output file and new file name"
  echo "   also specify input file you want to be warping " 
  echo " "
  echo "  Dependencies: freesurfer and its source file sourced"  
  # c3d must be in environment ( http://www.itksnap.org/pmwiki/pmwiki.php?n=Downloads.C3D ..i promise registration is painless!)"
  # echo "                ANTs must be in environment ( http://stnava.github.io/ANTs/ )"
  exit 1
fi

sublist=$1

# Next 4 lines are user-specified
aslprepdir=/project/ftdc_hcp/aslprep/aslprepout_20220124full/
aslpostdir=/project/ftdc_hcp/aslprep/bbrFlirt/bbrFlirtcbfOutput/
aslprepwrkdir=/project/ftdc_hcp/aslprep/wrkdir_20220124full/
freesurferdir=/project/ftdc_hcp/pipeline711/
# aslfiletag="acq-pcasl_mean_cbf"
bidsdir=/project/ftdc_hcp/aslprep/bids2/
scriptsdir=/project/ftdc_hcp/aslprep/aslpostp/scripts/
morescriptsdir=/project/ftdc_hcp/aslprep/bbrFlirt/scripts/

if [[ ! -d ${aslpostdir} ]] ; then 
  mkdir -p ${aslpostdir}
fi

if [[ ! -d ${aslpostdir}/logs/ ]] ; then
  mkdir -p ${aslpostdir}/logs/
fi

if [[ ! -d ${aslprepdir} ]] ; then 
  echo "${aslprepdir} does not exist...check path"
  echo " ....exiting..."
  exit 1
fi

if [[ ! -d ${aslprepwrkdir} ]] ; then
	echo "${aslprepwrkdir} does not exist...check path"
	echo " ....exiting..."
	exit 1
fi

for i in `cat ${sublist}` ; do 
  sub=$(echo $i | cut -d ',' -f1) 
  subfront=$(echo $sub | cut -c1-4)
  if [[ ${subfront} == "sub-" ]] ; then
	  sub=$(echo ${sub} | cut -c 5-)
  else
    sub="${sub}"
  fi 
  # outputfilename=${aslpostdir}/${sub}/${sub}_${outputfiletag}.nii.gz 
  cmd="bsub -J hcp_aslpost_bbrFlirtcbf_${sub} -o ${aslpostdir}/logs/hcp_aslpost_bbrFlirtcbf_${sub}.stdout ${morescriptsdir}/hcp_aslpost_bbrFlirtcbf.sh ${sub} ${aslprepdir} ${aslprepwrkdir} ${freesurferdir} ${aslpostdir} ${scriptsdir} ${bidsdir}"
  echo $cmd
  $cmd  
  sleep .12

done

