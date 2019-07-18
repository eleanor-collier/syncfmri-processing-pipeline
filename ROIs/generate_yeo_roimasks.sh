# Author: Eleanor Collier
# Date: August 28, 2018
# Creates the individual ROI masks for the 3 default network subsystems, and 2
# control networks (DAN & FPCN) from the Yeo et al, 2011 parcellation.
# Masks are normalized to refvol.
#
################################################################################----------
# USAGE: generate_yeo_masks.sh
################################################################################----------

# Directories, files & parameters to change
roi_dir=/dartfs-hpc/rc/lab/M/MeyerM/Collier/EmpOrient/ROIs/yeo_DMN_FPCN_DAN
refvol="/opt/fsl/5.0.7/data/standard/MNI152_T1_2mm_brain"

################################################################################
label='[YEO]'

pushd "${roi_dir}" >/dev/null

echo "${label} Extracting DMN, FPCN, DAN masks from 17 network parcellation"
## Extract the network masks: default
fslmaths -dt int FSL_17Networks_lib.nii.gz -thr 15 -uthr 15 -bin dn_mtl_mask
fslmaths -dt int FSL_17Networks_lib.nii.gz -thr 16 -uthr 16 -bin dn_core_mask
fslmaths -dt int FSL_17Networks_lib.nii.gz -thr 17 -uthr 17 -bin dn_dm_mask
## Extract the network masks: control networks (fpcn & dan)
fslmaths -dt int FSL_17Networks_lib -thr 5 -uthr 5 -bin control_dan1_mask
fslmaths -dt int FSL_17Networks_lib -thr 6 -uthr 6 -bin control_dan2_mask
fslmaths -dt int FSL_17Networks_lib -thr 11 -uthr 11 -bin control_fpcn1_mask
fslmaths -dt int FSL_17Networks_lib -thr 12 -uthr 12 -bin control_fpcn2_mask
fslmaths -dt int FSL_17Networks_lib -thr 13 -uthr 13 -bin control_fpcn3_mask

DMN_masks=(dn_mtl_mask dn_core_mask dn_dm_mask)
control_masks=(control_dan1_mask control_dan2_mask control_fpcn1_mask control_fpcn2_mask control_fpcn3_mask)

for mask in ${DMN_masks[@]}; do
	index_file=${mask%_mask}_index
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
			-bin roi_${index_file%_index.nii.gz}.${i}
	done
done

for mask in ${control_masks[@]}; do
	index_file=${mask%_mask}_index
	echo "${label} Apply warp to ${mask}"
	flirt -in ${mask} -ref ${refvol} -out w${mask} -applyxfm -usesqform -interp trilinear
	echo "${label} Create index for ${mask%_mask}"
	cluster -i w${mask} -t 0.99 --connectivity=26 \
	  -o ${mask%_mask}_index > ${mask}_clusters.txt
  #create separate ROIs from each value of index
	num_rois=$(fslstats ${index_file} -R | awk '{print int( $2 )}')
	echo "[GEN_ROI] Found ${num_rois} ROIs"
	for ((i=1;i<=${num_rois}; i++)); do
		echo "[GEN_ROI] Creating mask for ROI ${i}"
		fslmaths -dt int ${index_file} -thr ${i} -uthr ${i} \
			-bin roi_${index_file%_index.nii.gz}.${i}
	done
done

popd