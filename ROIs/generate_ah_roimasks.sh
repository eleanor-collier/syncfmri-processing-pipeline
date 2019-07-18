# Author: Eleanor Collier
# Date: August 28, 2018
# Creates the individual ROI masks for each Andrews-Hanna DMN ROI. Masks are 
# normalized to refvol.
#
################################################################################----------
# USAGE: generate_ah_masks.sh
################################################################################----------

# Directories, files & parameters to change
roi_dir=/dartfs-hpc/rc/lab/M/MeyerM/Collier/EmpOrient/ROIs/andrewshanna_DMN
refvol="/opt/fsl/5.0.7/data/standard/MNI152_T1_2mm_brain"

################################################################################

label='[ANDREWS-HANNA]'

pushd "${roi_dir}" >/dev/null

DMN_masks=(core_ampfc core_pcc dmpfc_ltc dmpfc_temppole dmpfc_tpj dmpfc dMPFCsubsytem \
	mtl_hf mtl_phc mtl_pipl mtl_rsp mtl_vmpfc)

for mask in ${DMN_masks[@]}; do
	index_file=${mask%_mask}
	echo "${label} Apply warp to ${mask}"
	flirt -in ${mask} -ref ${refvol} -out w${mask} -applyxfm -usesqform -interp trilinear
	echo "${label} Create index for ${mask%_mask}"
	cluster -i w${mask} -t 0.99 --connectivity=26 \
	  -o ${index_file} > ${mask}_clusters.txt

	num_rois=$(fslstats ${index_file} -R | awk '{print int( $2 )}')
	echo "[GEN_ROI] Found ${num_rois} ROIs"
	for ((i=1;i<=$num_rois; i++)); do
		echo "[GEN_ROI] Creating mask for ROI ${i}"
		fslmaths -dt int ${index_file} -thr ${i} -uthr ${i} \
			-bin roi_${index_file%.nii.gz}
	done
done

popd