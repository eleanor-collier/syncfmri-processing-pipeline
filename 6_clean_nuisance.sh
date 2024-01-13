  # Author: Eleanor Collier
# Date: August 26, 2018
# Clean nuisance regressors from EPI to get residuals for ROI time course extraction
#
################################################################################----------
# USAGE: clean_nuisance_rest.sh 01 02 03 ...
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
TEMPLATE_DIR=$PROJECT_DIR/code/templates #path to look for feat templates
PREP_DIR=$PROJECT_DIR/analysis/prep #path to look for preprocessed data
DATA_DIR=$PROJECT_DIR #path to look for raw data

# Data info
UNWARPING_APPLIED=1 #was unwarping applied to the data beforehand? 1=yes, 0=no

# Settings
TR=1.5
HFILTER=111
TEMPFILT=1
TEMPDERIV=1

################################################################################
main() {
  for subj in $subj_list; do
    mk_template_dir
    for t in $(eval echo $TASKS); do
      def_vars
      populate_fsf_script
      run_fsf_script &
      sleep 5
    done  
  done
  wait
}


# Make subject template directory
mk_template_dir() {
  sub_template_dir=$PREP_DIR/cleaned/sub-${subj}/${SESSION}
  if [ ! -d "$sub_template_dir" ]; then
    mkdir -p "$sub_template_dir"
  fi
}


# Get subject/run-specific info for template
def_vars() {
  label="[SUBJECT $subj RUN ${t}:]"

  # If unwarping was applied, add suffix "_unwarped to func data"
  if [ UNWARPING_APPLIED = 1 ]; then func_suffix="_unwarped"; 
  elif [ UNWARPING_APPLIED = 0 ]; then func_suffix=""; fi
  func_data="$DATA_DIR/sub-${subj}/${SESSION}/func/*task-${t}*bold${func_suffix}.nii.gz"

  preproc_dir=${PREP_DIR}/preprocessed/sub-${subj}/${SESSION}/${t}.feat
  output_dir=${PREP_DIR}/cleaned/sub-${subj}/${SESSION}/${t}.feat
  nuisance_dir="$preproc_dir/nuisance"
  mc_dir="${nuisance_dir}/mc"
  mo_dir="${nuisance_dir}/mo"
  nvols=$( fslnvols $func_data )
}
  

# Populate the glm template
populate_fsf_script() {
  echo "${label} rendering the design template"
  cat $TEMPLATE_DIR/clean_nuisance.fsf \
    | sed "s|<<func_data>>|$func_data|g" \
    | sed "s|<<output_dir>>|$output_dir|g" \
    | sed "s|<<TR>>|${TR}|g" \
    | sed "s|<<nvols>>|$nvols|g" \
    | sed "s|<<hFilter>>|${HFILTER}|g" \
    | sed "s|<<tempFilt>>|${TEMPFILT}|g" \
    | sed "s|<<tempDeriv>>|${TEMPDERIV}|g" \
    | sed "s|<<MOTION1>>|${mc_dir}/motion1.par|g" \
    | sed "s|<<MOTION2>>|${mc_dir}/motion2.par|g" \
    | sed "s|<<MOTION3>>|${mc_dir}/motion3.par|g" \
    | sed "s|<<MOTION4>>|${mc_dir}/motion4.par|g" \
    | sed "s|<<MOTION5>>|${mc_dir}/motion5.par|g" \
    | sed "s|<<MOTION6>>|${mc_dir}/motion6.par|g" \
    | sed "s|<<OUTLIERS>>|${mo_dir}/outliers.txt|g" \
    | sed "s|<<WM>>|${nuisance_dir}/WM_meants.txt|g" \
    | sed "s|<<CSF>>|${nuisance_dir}/CSF_meants.txt|g" \
    | sed "s|<<GLOBAL>>|${nuisance_dir}/WB_meants.txt|g" \
    > $sub_template_dir/clean_${t}.fsf
}


# If analysis has not been run, execute template in FEAT
run_fsf_script() {
  if [ ! -d "$output_dir" ]; then   
    echo "${label} starting FEAT cleaning"
    feat $sub_template_dir/clean_${t}.fsf
    sleep 10
  else
    echo "${label} EPI has already been cleaned"
  fi
}


main "$@"
