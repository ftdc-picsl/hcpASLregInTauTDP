#!/bin/bash
subjlist=$1
module load ANTs/2.3.5
for i in `cat $subjlist`; do
	ThresholdImage 3 ../bbrmanual_cbf_to_t1Output/sub-${i}/bbr_out/sub-${i}.nii.gz ../bbrmanual_cbf_to_t1Output/sub-${i}/bbr_out/sub-${i}fastmask.nii.gz .01 Inf 1 0 

       CreateTiledMosaic -i /project/ftdc_hcp/pipeline711/${i}/mri/T1-converted.nii.gz -e [../bbrmanual_cbf_to_t1Output/sub-${i}/bbr_out/sub-${i}.nii.gz,../bbrmanual_cbf_to_t1Output/sub-${i}/bbr_out/sub-${i}fastmask.nii.gz] -a .5 -t 7x7 -s [4,65,265] -o ../bbrmanual_cbf_to_t1Output/sub-${i}/bbr_out/sub-${i}_manual_bbr_on_t1-converted.png
done        
