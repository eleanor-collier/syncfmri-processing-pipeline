# Author: Eleanor Collier
# Date: August 28, 2018
# Creates the individual ROI masks for the desired network subsystems from the 
# Yeo et al, 2011 parcellation.
# Masks are normalized to refvol.
#
################################################################################----------
# USAGE: generate_yeo_masks.sh
################################################################################----------

# Directories, files & parameters to change
roi_dir=/home/ecollier/SyncDisclosures/ROIs/yeo
refvol="/usr/local/fsl/data/standard/MNI152_T1_2mm_brain"

################################################################################
label='[YEO]'

pushd "${roi_dir}" >/dev/null

echo "${label} Extracting masks from 17 network parcellation"
## Extract the network masks: default mode
fslmaths -dt int FSL_17Networks_lib.nii.gz -thr 14 -uthr 14 -bin dn_other_mask
fslmaths -dt int FSL_17Networks_lib.nii.gz -thr 15 -uthr 15 -bin dn_mtl_mask
fslmaths -dt int FSL_17Networks_lib.nii.gz -thr 16 -uthr 16 -bin dn_core_mask
fslmaths -dt int FSL_17Networks_lib.nii.gz -thr 17 -uthr 17 -bin dn_dm_mask
## Extract the network masks: dan
fslmaths -dt int FSL_17Networks_lib -thr 5 -uthr 5 -bin dan1_mask
fslmaths -dt int FSL_17Networks_lib -thr 6 -uthr 6 -bin dan2_mask
## Extract the network masks: somatomotor
fslmaths -dt int FSL_17Networks_lib -thr 3 -uthr 3 -bin somatomotor1_mask
fslmaths -dt int FSL_17Networks_lib -thr 4 -uthr 4 -bin somatomotor2_mask

masks=(dn_other_mask dn_mtl_mask dn_core_mask dn_dm_mask dan1_mask dan2_mask somatomotor1_mask somatomotor2_mask)

for mask in ${masks[@]}; do
	index_file=${mask%_mask}_index

	# Warp mask to reference volume
	echo "${label} Apply warp to ${mask}"
	flirt -in ${mask} -ref ${refvol} -out w${mask} -applyxfm -usesqform -interp trilinear

	# Create cluster index for network mask
	echo "${label} Create index for ${mask%_mask}"
	cluster -i w${mask} -t 0.99 --connectivity=26 \
	  -o ${index_file} > ${mask}_clusters.txt

	# Create ROI masks for each cluster identified in network mask
	num_rois=$(fslstats ${index_file} -R | awk '{print int( $2 )}')
	echo "[GEN_ROI] Found ${num_rois} ROIs"
	for ((i=1;i<=$num_rois; i++)); do
		echo "[GEN_ROI] Creating mask for ROI ${i}"
		fslmaths -dt int ${index_file} -thr ${i} -uthr ${i} \
			-bin roi_${index_file%_index.nii.gz}.${i}
	done
done

popd