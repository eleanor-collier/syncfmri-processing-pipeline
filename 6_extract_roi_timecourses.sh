# Author: Eleanor Collier
# Date: August 22, 2018
# Extract timecourse for each ROI in ROI_DIR and subdirectories
#
################################################################################----------
# USAGE: extract_roi_timecourse.sh 01 02 03 ...
################################################################################----------

subj_list="$@"

# Scan session info
RUNS="02 07 12" #runs to loop through

# Directories
PROJECT_DIR=/dartfs-hpc/rc/lab/M/MeyerM/Collier/EmpOrient #path to project
ANAL_DIR=$PROJECT_DIR/analysis/restTimecourses #path to output time course data
PREP_DIR=$PROJECT_DIR/analysis/restPrep #path to look for cleaned/preprocessed data
ROI_DIR=$PROJECT_DIR/ROIs #path to look for ROI masks

################################################################################
main() {
  for subj in $subj_list; do
	for r in $RUNS; do
  	  def_vars
  	  get_roi_timecourses &
  	  sleep 5
  	done
  done
  wait
}


# Define subject/run-specific info
def_vars() {
  label="[SUBJECT $subj RUN ${r}:]"    
  preproc_dir="${PREP_DIR}/preprocessed/sub-${subj}/rest_run${r}.feat"
  clean_dir="${PREP_DIR}/cleaned/sub-${subj}/rest_run${r}.feat/stats"
  output_dir="${ANAL_DIR}/sub-${subj}/rest_run${r}"
  epi="res4d.nii.gz"
}


# Get ROI timecourses for subject & run if they don't already exist
get_roi_timecourses() {
  if [ ! -d $output_dir ]; then
    echo "${label} Extracting time courses from ${epi}"
    setup
    
    # Get timecourses for all ROIs in all ROI directories
    dirs=$(ls -d -- $ROI_DIR/*)
    for dir in $dirs; do
      for mask in $dir/roi_*.nii*; do
      	mask_name=$(basename $mask)
      	transform_roi
      	get_roi_timecourse &
      	sleep 5
      done
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
