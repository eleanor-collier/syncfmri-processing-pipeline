# Author: Eleanor Collier
# Date: August 28, 2018
# Creates the individual ROI masks for the desired network subsystems from the 
# Fedorenko et al. language network, optionally restricting to voxels in the 
# LanA network with high probabilities of overlap between participants.
# Masks are normalized to REF_VOL.
#
################################################################################----------
# USAGE: generate_language_masks.sh
################################################################################----------

# Directories, files & parameters to change
ROI_DIR=/home/ecollier/SyncDisclosures/ROIs/language
REF_VOL="/usr/local/fsl/data/standard/MNI152_T1_2mm_brain"

MASKS=(language_LH_IFGorb language_LH_IFG language_LH_MFG language_LH_AntTemp \
	language_LH_PostTemp language_LH_AngG language_RH_IFGorb language_RH_IFG \
	language_RH_MFG language_RH_AntTemp language_RH_PostTemp language_RH_AngG)

USE_LAN_A=1      # 1= Restrict voxels to LanA network; 0=Use all voxels
PROP_VOXELS=0.10 # If using LanA, this is the proportion of voxels that will be used in a given ROI

################################################################################
main() {
  def_vars
  pushd "${ROI_DIR}" >/dev/null
  extract_network_masks
  for mask in ${MASKS[@]}; do
    echo ${mask}
    create_roi_masks &
    sleep 2
  done
  wait
  popd
}

def_vars() {
  label='[LANGUAGE]'
}

extract_network_masks() {
  echo "${label} Extracting masks from Federenko et al. language parcels"
  ## Extract the network masks: Federenko et al. language parcels
  fslmaths -dt int fedorenko_parcels.nii.gz -thr 1 -uthr 1 -bin language_LH_IFGorb
  fslmaths -dt int fedorenko_parcels.nii.gz -thr 2 -uthr 2 -bin language_LH_IFG
  fslmaths -dt int fedorenko_parcels.nii.gz -thr 3 -uthr 3 -bin language_LH_MFG
  fslmaths -dt int fedorenko_parcels.nii.gz -thr 4 -uthr 4 -bin language_LH_AntTemp
  fslmaths -dt int fedorenko_parcels.nii.gz -thr 5 -uthr 5 -bin language_LH_PostTemp
  fslmaths -dt int fedorenko_parcels.nii.gz -thr 6 -uthr 6 -bin language_LH_AngG
  fslmaths -dt int fedorenko_parcels.nii.gz -thr 7 -uthr 7 -bin language_RH_IFGorb
  fslmaths -dt int fedorenko_parcels.nii.gz -thr 8 -uthr 8 -bin language_RH_IFG
  fslmaths -dt int fedorenko_parcels.nii.gz -thr 9 -uthr 9 -bin language_RH_MFG
  fslmaths -dt int fedorenko_parcels.nii.gz -thr 10 -uthr 10 -bin language_RH_AntTemp
  fslmaths -dt int fedorenko_parcels.nii.gz -thr 11 -uthr 11 -bin language_RH_PostTemp
  fslmaths -dt int fedorenko_parcels.nii.gz -thr 12 -uthr 12 -bin language_RH_AngG
}

create_roi_masks() {
	# Warp mask to reference volume
	echo "${label} Apply warp to ${mask}"
	flirt -in ${mask} -ref ${REF_VOL} -out w${mask} -applyxfm -usesqform -interp trilinear
	
	# Use LanA mask to restrict voxels in language network region
	if [ $USE_LAN_A == 1 ]; then
    echo "${label} Using Lan A mask to select voxels in ${mask}"
    # Create tmp folder for calculations
    if [ ! -d "tmp" ]; then
      mkdir -p tmp
    fi
	  create_LanA_mask_for_region
	  fslmaths w${mask} -mul tmp/LanA_region_mask roi_${mask}
	else
	  cp w${mask} roi_${mask}
  fi
}

create_LanA_mask_for_region() {
  # Print LanA probabilities of all voxels in mask to output file
  fslmeants -i LanA_n806.nii -m w${mask} --showall | head -4 | tail -1 > tmp/LanA_region_step1.txt
  # Rearrange into columns
  tr -s ' '  '\n'< tmp/LanA_region_step1.txt > tmp/LanA_region_step2.txt
  # Sort descending
  sort -rg tmp/LanA_region_step2.txt > tmp/LanA_region_step3.txt
  # Get total number of voxels
  total=`awk 'END { print NR }' tmp/LanA_region_step3.txt`
  # Get desired proportion of voxels with highest probability values
  n_desired=`awk -vp=$total -vq=$PROP_VOXELS 'BEGIN{printf "%.0f" ,p * q}'`
  head -n $n_desired tmp/LanA_region_step3.txt > tmp/LanA_region_step4.txt
  # Get lowest probability value and set as min threshold for generating clusters
  ROI_probability_cutoff=`tail -1 tmp/LanA_region_step4.txt`
  echo "${label} LanA probability cutoff for region = " ${ROI_probability_cutoff}
  # Create LanA mask using probability cutoff
  fslmaths LanA_n806.nii.gz -thr ${ROI_probability_cutoff} -bin tmp/LanA_region_mask
}

main "$@"
