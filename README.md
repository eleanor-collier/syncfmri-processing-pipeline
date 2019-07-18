# FSL-rest-pipeline-BIDS
FSL pipeline to preprocess fMRI rest period data and extract ROI time courses. Set up to work with BIDS format data. Follow steps below carefully.

BEFORE BEGINNING PIPELINE
1. Run transfer_fMRI_data.sh for each subject:
    -Transfers data from BIDS folder on Rolando server to study folder on Discovery, and swaps out SIDs in filenames with subject numbers
    -You will be prompted for your Rolando password, which is by default Change!t
    -Script handles one subject at a time
2. Run unzip_files.sh
    -Unzips anatomical & functional niftis so you can open them in SPM (step 3)
    -Script can handle as many subjects as you specify
3. Reorient anatomical & functional niftis
    -Follow this guide: https://docs.google.com/document/d/1jp0XflzEsHiiv8q96jHW16ihkIazlIETKaaRH_hq72E/edit?usp=sharing
4. Run zip_files.sh
    -Zips anatomical & functional niftis again for FSL pipeline


PIPELINE STEPS
1.
2.
3.
4.
5.
6.
