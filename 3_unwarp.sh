# Author: Eleanor Collier
# Date: March 28, 2023
# This script uses FSL's topup tool to unwarp functional images using AP/PA field maps 
# 
################################################################################----------
# USAGE: unwarp.sh 01 02 03 ...
################################################################################----------

subj_list=$@

# Scan session info
SESSION="ses-syncspeak" #name of session in BIDS file structure, leave as "" if none
TASKS={pos1,pos2,neg1,neg2} #task runs to loop through (content in brackets will be permuted)
# TASKS Usage: For speaking sessions, use the following format: {pos1,pos2,neg1,neg2}
# For listening sessions, use the following format: {speaker#,speaker#,speaker#,speaker#}{pos1,pos2,neg1,neg2}
# If there is only one speaker, remove the brackets around speaker#

# Directories
DATA_DIR=/home/ecollier/SyncDisclosures #path to look for raw data
PARAMS_DIR=/home/ecollier/SyncDisclosures/code/templates #path to look for acquisition parameters

################################################################################
main() {
  for subj in $subj_list; do
    def_vars
    create_merged_fmap
    for t in $(eval echo $TASKS); do
      apply_fmap &
      sleep 2
    done
    # cleanup
  done
  wait
}


# Define subject-specific info
def_vars() {
  label="[SUBJECT $subj:]"    
  fmap_dir=$DATA_DIR/sub-${subj}/${SESSION}/fmap
  func_dir=$DATA_DIR/sub-${subj}/${SESSION}/func
  tmp_dir=$fmap_dir/topup_tmp
}

# Merge AP/PA files into single field map
create_merged_fmap() {
  echo "${label} creating merged field map"
  pushd "${fmap_dir}" >/dev/null
  if [ ! -d ${tmp_dir} ]; then
    mkdir ${tmp_dir}
    fslmerge -t ${tmp_dir}/AP_PA.nii.gz *AP_epi.nii.gz *PA_epi.nii.gz
    topup --imain=${tmp_dir}/AP_PA.nii.gz --datain=${PARAMS_DIR}/acq_params.txt --config=b02b0.cnf --out=${tmp_dir}/topup_AP_PA
  fi
  popd
}


# Use field map to unwarp functional image
apply_fmap() {
  pushd "${func_dir}" >/dev/null
  func_data=(*task-${t}*bold.nii.gz)
  func_data_name=${func_data%%.*}
  echo "${label} unwarping" ${func_data_name}
  applytopup --imain=${func_data} --topup=${tmp_dir}/topup_AP_PA --datain=${PARAMS_DIR}/acq_params.txt \
    --inindex=1 --out=${func_data_name}_unwarped --method=jac &
  popd
}


# Delete output files created by topup
cleanup() {
  echo "${label} deleting extraneous files"
  rm -r ${tmp_dir}
}


main "$@"
