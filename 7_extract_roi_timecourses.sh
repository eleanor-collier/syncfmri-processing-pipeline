# Author: Eleanor Collier
# Date: August 22, 2018
# Extract timecourse for each ROI in ROI_DIR and subdirectories
#
################################################################################----------
# USAGE: extract_roi_timecourse.sh 01 02 03 ...
################################################################################----------

subj_list="$@"

SESSION="ses-syncspeak" #name of session in BIDS file structure, leave as "" if none
TASKS={pos1,pos2,neg1,neg2} #task runs to loop through (content in brackets will be permuted)
# TASKS Usage: For speaking sessions, use the following format: {pos1,pos2,neg1,neg2}
# For listening sessions, use the following format: {speaker#,speaker#,speaker#,speaker#}{pos1,pos2,neg1,neg2}
# If there is only one speaker, remove the brackets around speaker#

# Directories
PROJECT_DIR=/home/ecollier/SyncDisclosures #path to project
ANAL_DIR=$PROJECT_DIR/analysis/roi_timecourses #path to output time course data
PREP_DIR=$PROJECT_DIR/analysis/prep #path to look for cleaned/preprocessed data
ROI_DIR=$PROJECT_DIR/ROIs #path to look for ROI masks

################################################################################
main() {
  for subj in $subj_list; do
    for t in $(eval echo $TASKS); do
  	  def_vars
  	  get_roi_timecourses &
  	  sleep 5
  	done
  done
  wait
}


# Define subject/run-specific info
def_vars() {
  label="[SUBJECT $subj RUN ${t}:]"    
  preproc_dir="${PREP_DIR}/preprocessed/sub-${subj}/${SESSION}/${t}.feat"
  clean_dir="${PREP_DIR}/cleaned/sub-${subj}/${SESSION}/${t}.feat/stats"
  output_dir="${ANAL_DIR}/sub-${subj}/${SESSION}/${t}"
  epi="res4d.nii.gz"
}


# Get ROI timecourses for subject & run if they don't already exist
get_roi_timecourses() {
  if [ ! -d $output_dir ]; then
    echo "${label} Extracting time courses from ${epi}"
    setup
    
    # Get timecourses for all ROIs in ROI directory & subdirectories
    for mask in $(find $ROI_DIR -type f -iname "roi_*.nii*"); do
        mask_name=$(basename $mask)
        transform_roi
        get_roi_timecourse &
        sleep 5
    done
    wait

    save_roi_timecourses
    cleanup
    echo "${label} DONE. $(date)"
  else
  	echo "${label} ROI timecourses have already been extracted"
  fi
}

# Create directories for temporary processing & final output
setup() {
    tmp_dir=$(mktemp -d --tmpdir rst_time.XXXXXX)
    mkdir -p ${output_dir}
}


# Convert ROI mask to from standard to functional image space
transform_roi() {
  echo "${label} converting ${mask_name} to same coordinates as epi"
  flirt -in "$mask" \
  		  -ref "${preproc_dir}/reg/example_func.nii.gz" \
  	    -applyxfm \
  	    -init "${preproc_dir}/reg/standard2example_func.mat" \
  	    -out "${tmp_dir}/${mask_name}"
  fslmaths "${tmp_dir}/${mask_name}" -thr 0.9 -bin
}


get_roi_timecourse() {
  # Create txt file to store individual ROI time course
  touch "${tmp_dir}/time_${mask_name%.nii.gz}.txt"

  # Extract ROI time course
  echo "${label} processing ROI ${mask_name}"
  fslmeants -i "${clean_dir}/${epi}" \
            -o "${tmp_dir}/time_${mask_name%.nii.gz}.txt" \
            -m "${tmp_dir}/${mask_name}"

  # Add name of mask to top of timecourse file & delete mask from tmp folder
  sed -i "1s/^/${mask_name%.nii.gz}\n/" "${tmp_dir}/time_${mask_name%.nii.gz}.txt"
  rm "${tmp_dir}/${mask_name}"
} 


# Create txt file to store all ROI time courses
save_roi_timecourses() {
  touch "${tmp_dir}"/time_all.txt
  paste "${tmp_dir}"/time_* > "${tmp_dir}"/time_all.txt
}


# Copy contents of temporary directory to output directory
cleanup() {
  rsync -a "${tmp_dir}/" "${output_dir}/"
  rm -rf "${tmp_dir}"
}


main "$@"
