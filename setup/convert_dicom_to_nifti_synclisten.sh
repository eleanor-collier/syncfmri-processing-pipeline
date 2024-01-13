# Author: Eleanor Collier
# Date: March 21, 2023
# Converts one subject's brain data from dicom to nifti & formats in BID format
# Requires dcm2bids & dcm2niix packages
################################################################################----------
# USAGE: convert_dicom_to_nifti.sh subj_id session
################################################################################----------

subj_id=$1 #Example: 02
session=$2 #Example: synclisten1

# Directories, files & parameters to change
PROJ_FOLDER="/Volumes/Research Project/Eleanor/SyncDisclosures_fMRI/Imaging" #main project folder
GET_CONFIG_HERE="/Users/Eleanor2/Library/CloudStorage/GoogleDrive-airfire246@gmail.com/My Drive/UCR/UCR SNL/Research Projects/SyncDisclosures/fMRI/Analysis/processing_pipeline/process_fmri_data/setup/bids_config"
GET_DATA_HERE=${PROJ_FOLDER}/sourcedata/sub-${subj_id}/ses-${session} #subject folder with dicom data
SEND_DATA_HERE=${PROJ_FOLDER} #subject folder for nifti data

LABEL="[SUBJECT ${subj_id}:]"

################################################################################
main() {
  if [ ! -d "${SEND_DATA_HERE}/sub-${subj_id}/ses-${session}" ]; then
    convert_data
    clean_up
  else
    echo "${LABEL} data already converted"
  fi
}

# Convert data using dcm2bids (implements dcm2niix under the hood)
convert_data() {
  # Run dcm2bids
  dcm2bids -d "${GET_DATA_HERE}" -p ${subj_id} -s ${session} -c "${GET_CONFIG_HERE}/${session}_P${subj_id}_config.json" -o "${SEND_DATA_HERE}" --forceDcm2niix
}

# Clean up tmp folder generated by dcm2bids
clean_up() {
  rm -rf "${SEND_DATA_HERE}/tmp_dcm2bids"
}

main "$@"