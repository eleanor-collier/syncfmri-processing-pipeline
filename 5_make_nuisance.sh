# Author: Eleanor Collier
# Date: August 22, 2018
#
# Create nuisance regressors for intersubject connectivity analysis.
# Options available: generating motion regressors from mcflirt output, creating white matter, 
# CSF, and whole brain mean nuisance regressors.
#
################################################################################----------
# USAGE: make_nuisance.sh 01 02 03 ...
################################################################################----------

subj_list="$@"

# Scan session info
SESSION="ses-syncspeak" #name of session in BIDS file structure, leave as "" if none
TASKS={pos1,pos2,neg1,neg2} #task runs to loop through (content in brackets will be permuted)
# TASKS Usage: For speaking sessions, use the following format: {pos1,pos2,neg1,neg2}
# For listening sessions, use the following format: {speaker#,speaker#,speaker#,speaker#}{pos1,pos2,neg1,neg2}
# If there is only one speaker, remove the brackets around speaker#

# Directories
PROJECT_DIR=/home/ecollier/SyncDisclosures #path to project
PREP_DIR=$PROJECT_DIR/analysis/prep #path to output nuisance regressors
DATA_DIR=$PROJECT_DIR #path to look for raw data

# Input Volumes
VENTRICLE_VOL=/usr/local/fsl/data/standard/MNI152_T1_2mm_VentricleMask.nii.gz
ANAT_VOL=*"brain.nii.gz"
CSF_VOL=*"CSF.nii.gz"
WM_VOL=*"WM.nii.gz"

# Data info
UNWARPING_APPLIED=1 #was unwarping applied to the data beforehand? 1=yes, 0=no

# Settings (1=create nuisance regressors, 0=ignore)
CSF=1 # Cerebrospinal fluid
WM=1  # White matter
WB=0  # Whole brain
MC=1  # Motion correction (adjust brain signal based on motion in each TR)
MO=1  # Motion outliers (model out TRs with too much motion)

################################################################################
main() {
  for subj in $subj_list; do
    for t in $(eval echo $TASKS); do
      def_vars
      make_nuissance_regs &
      sleep 2
    done
  done
  wait
}


# Define subject/run-specific info
def_vars() {
  label="[SUBJECT $subj RUN ${t}:]"

  # If unwarping was applied, add suffix "_unwarped to func data"
  if [ UNWARPING_APPLIED = 1 ]; then func_suffix="_unwarped"; 
  elif [ UNWARPING_APPLIED = 0 ]; then func_suffix=""; fi
  raw_epi="$DATA_DIR/sub-${subj}/${SESSION}/func/*task-${t}*bold${func_suffix}.nii.gz"

  output_dir=${PREP_DIR}/preprocessed/sub-${subj}/${SESSION}/${t}.feat/nuisance
  preproc_dir=${PREP_DIR}/preprocessed/sub-${subj}/${SESSION}/${t}.feat
  anat_dir="$DATA_DIR/sub-${subj}/${SESSION}/anat"
  filtered_epi="filtered_func_data.nii.gz"
}


# If regressors have not yet been created, generate regressors
make_nuissance_regs() {
  if [ ! -d $output_dir ]; then
    setup
    # Get motion correction regressors
    if [ $MC == 1 ]; then
      get_motion_correction &
    fi
    # Get motion outliers
    if [ $MO == 1 ]; then
      get_motion_outliers &
    fi
    #Generate white matter mask & extract timecourse
    if [ $WM == 1 ] ; then
      get_tissue_timecourse "WM_mask" $WM_VOL "WM_meants.txt" 0 & 
    fi
    #Generate CSF mask & extract timecourse
    if [ $CSF == 1 ] ; then
      get_tissue_timecourse "CSF_mask" $CSF_VOL "CSF_meants.txt" 1 &
    fi
    #Generate whole brain mask & extract timecourse
    if [ $WB == 1 ] ; then
      get_tissue_timecourse "WB_mask" $ANAT_VOL "WB_meants.txt" 0 &
    fi
    wait
    cleanup
    echo "${label} DONE. $(date)"
  else
    echo "${label} nuisance regressors have already been created"
  fi
}


# Create directories for temporary processing & final output
setup() {
    tmp_dir=$(mktemp -d --tmpdir sync_prep.XXXXXX)
    fslmaths "${preproc_dir}/${filtered_epi}" -nan "${tmp_dir}/${filtered_epi}"
    mkdir -p ${output_dir}
}

# Motion regressors: change from 1 file with 6 columns to 1 file per parameter
get_motion_correction() {
  mc_dir="${tmp_dir}/mc"
  echo "${label} creating motion regressors for ${filtered_epi}"
  mkdir -p "${mc_dir}"
  cat "${preproc_dir}/mc/prefiltered_func_data_mcf.par" \
      | tr -s " " | sed 's/^[[:blank:]]*//g' > "${mc_dir}/func_mcf.par"
  # Create one file per column of motion pars
  cut -d ' ' -f 1  "${mc_dir}/func_mcf.par" > "${mc_dir}/motion1.par"
  cut -d ' ' -f 2  "${mc_dir}/func_mcf.par" > "${mc_dir}/motion2.par"
  cut -d ' ' -f 3  "${mc_dir}/func_mcf.par" > "${mc_dir}/motion3.par"
  cut -d ' ' -f 4  "${mc_dir}/func_mcf.par" > "${mc_dir}/motion4.par"
  cut -d ' ' -f 5  "${mc_dir}/func_mcf.par" > "${mc_dir}/motion5.par"
  cut -d ' ' -f 6  "${mc_dir}/func_mcf.par" > "${mc_dir}/motion6.par"
}


get_motion_outliers() {
  mo_dir="${tmp_dir}/mo"
  echo "${label} creating motion outliers for raw_epi"
  mkdir -p "${mo_dir}"
  fsl_motion_outliers -i $raw_epi -o "${mo_dir}/outliers.txt" \
  	--fd --thresh=0.2
  if [ ! -f "${mo_dir}/outliers.txt" ]; then
    echo "${label} no outliers detected; file of zeroes"
    touch "${mo_dir}/outliers.txt"
    # create file of zeroes with length equal to number of volumes
    nvols=$( fslnvols ${raw_epi} )
    for i in $( seq 1 $nvols ); do
      printf '0\n'
    done >"${mo_dir}/outliers.txt"
  fi
}


get_tissue_timecourse() {
  mask_name=$1  # name of tissue mask
  vol=$2        # volume containing segmented tissue
  ts_file=$3    # txt file to store timecourses in
  ventricles=$4 # whether to confine mask region to ventricles, 1 or 0
  create_mask
  transform_mask
  echo "${label} extracting ${mask_name} timecourse"
  fslmeants -i "${tmp_dir}/${filtered_epi}" -o "${tmp_dir}/${ts_file}" \
    -m "${tmp_dir}/${mask_name}"
}


# Create mask from subject's relevant tissue volume
create_mask() {
  if [[ $ventricles == 1 ]]; then
  	create_ventricle_mask
  	echo "${label} creating ${mask_name}"
  	fslmaths ${anat_dir}/${vol} -nan -mas "${tmp_dir}/ventricle_mask" "${tmp_dir}/${mask_name}"
    fslmaths ${tmp_dir}/${mask_name} -nan -thr 0.1 -bin -ero "${tmp_dir}/${mask_name}"
  else
  	echo "${label} creating ${mask_name}"
  	fslmaths ${anat_dir}/${vol} -nan -thr 0.1 -bin -ero "${tmp_dir}/${mask_name}"
  fi
}


create_ventricle_mask() {
  echo "${label} creating ventricle mask"
  fslmaths ${VENTRICLE_VOL} -nan -thr 0.1 -bin -ero "${tmp_dir}/ventricle_mask"
  # Convert from MNI space to subject's anatomical space
  flirt -in "${tmp_dir}/ventricle_mask" \
        -ref ${anat_dir}/${ANAT_VOL} \
        -applyxfm \
        -init "${preproc_dir}/reg/standard2highres.mat" \
        -out "${tmp_dir}/ventricle_mask"
}


# Convert mask from anatomical to functional image space
transform_mask() {
  echo "${label} converting ${mask_name} to same dimensions as filtered_epi"
  flirt -in "${tmp_dir}/${mask_name}" \
        -ref "${preproc_dir}/reg/example_func.nii.gz" \
        -applyxfm \
        -init "${preproc_dir}/reg/highres2example_func.mat" \
        -out "${tmp_dir}/${mask_name}"
  fslmaths "${tmp_dir}/${mask_name}" -thr 0.9 -bin
}


cleanup() {
  # Copy contents of temporary directory to output directory
  rm "${tmp_dir}/${filtered_epi}"
  rsync -a "${tmp_dir}/" "${output_dir}/"
  rm -rf "${tmp_dir}"
}


main "$@"
