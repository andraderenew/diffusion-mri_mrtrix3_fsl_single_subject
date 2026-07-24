#!/usr/bin/env bash
set -euo pipefail

WORK="/media/andraderenew/Elements/neuroimaging/diffusion-mri_mrtrix3_fsl_single_subject"
RAW="$WORK/data/raw/sub-010142/ses-01/dwi"
DERIV="$WORK/derivatives"
REPO="$HOME/github/diffusion-mri_mrtrix3_fsl_single_subject"
SCRATCH="$HOME/mrtrix_scratch"

DWI="$RAW/sub-010142_ses-01_dwi.nii.gz"
BVAL="$RAW/sub-010142_ses-01_dwi.bval"
BVEC="$RAW/sub-010142_ses-01_dwi.bvec"
JSON="$RAW/sub-010142_ses-01_dwi.json"

mkdir -p "$DERIV" "$SCRATCH" "$REPO/results/tables"

for file in "$DWI" "$BVAL" "$BVEC" "$JSON"; do
  [[ -f "$file" ]] || { echo "ERROR: falta $file"; exit 1; }
done

mrconvert "$DWI" "$DERIV/dwi_raw.mif" \
  -fslgrad "$BVEC" "$BVAL" \
  -json_import "$JSON" \
  -force

dwidenoise "$DERIV/dwi_raw.mif" "$DERIV/dwi_denoised.mif" \
  -noise "$DERIV/noise_map.mif" \
  -nthreads 12 \
  -force

mrcalc "$DERIV/dwi_raw.mif" "$DERIV/dwi_denoised.mif" \
  -subtract "$DERIV/denoise_residual.mif" \
  -force

mrdegibbs "$DERIV/dwi_denoised.mif" "$DERIV/dwi_degibbs.mif" \
  -nthreads 12 \
  -force

rm -rf "$DERIV/eddy_qc"

dwifslpreproc "$DERIV/dwi_degibbs.mif" "$DERIV/dwi_preproc.mif" \
  -rpe_none \
  -pe_dir j- \
  -readout_time 0.04914 \
  -eddy_options " --repol " \
  -eddyqc_all "$DERIV/eddy_qc" \
  -export_grad_fsl "$DERIV/dwi_preproc.bvec" "$DERIV/dwi_preproc.bval" \
  -scratch "$SCRATCH" \
  -force

dwiextract "$DERIV/dwi_preproc.mif" - -bzero |
  mrmath - mean "$DERIV/mean_b0.mif" -axis 3 -force

dwi2mask "$DERIV/dwi_preproc.mif" "$DERIV/dwi_mask.mif" \
  -nthreads 12 \
  -force

dwi2tensor "$DERIV/dwi_preproc.mif" "$DERIV/dti_tensor.mif" \
  -mask "$DERIV/dwi_mask.mif" \
  -b0 "$DERIV/dti_b0.mif" \
  -nthreads 12 \
  -force

tensor2metric "$DERIV/dti_tensor.mif" \
  -mask "$DERIV/dwi_mask.mif" \
  -fa "$DERIV/fa.mif" \
  -adc "$DERIV/md.mif" \
  -ad "$DERIV/ad.mif" \
  -rd "$DERIV/rd.mif" \
  -vector "$DERIV/eigenvector1.mif" \
  -nthreads 12 \
  -force

{
  printf "metric\tmean\tmedian\tstd\n"
  for metric in fa md ad rd; do
    mean="$(mrstats "$DERIV/${metric}.mif" -mask "$DERIV/dwi_mask.mif" -output mean)"
    median="$(mrstats "$DERIV/${metric}.mif" -mask "$DERIV/dwi_mask.mif" -output median)"
    std="$(mrstats "$DERIV/${metric}.mif" -mask "$DERIV/dwi_mask.mif" -output std)"
    printf "%s\t%s\t%s\t%s\n" "$metric" "$mean" "$median" "$std"
  done
} > "$REPO/results/tables/table1_global_dti_metrics.tsv"

dwi2response tournier "$DERIV/dwi_preproc.mif" "$DERIV/response_wm.txt" \
  -mask "$DERIV/dwi_mask.mif" \
  -nthreads 12 \
  -force

dwi2fod csd "$DERIV/dwi_preproc.mif" \
  "$DERIV/response_wm.txt" "$DERIV/wm_fod.mif" \
  -mask "$DERIV/dwi_mask.mif" \
  -nthreads 12 \
  -force

tckgen "$DERIV/wm_fod.mif" "$DERIV/tracks_500k.tck" \
  -algorithm iFOD2 \
  -seed_dynamic "$DERIV/wm_fod.mif" \
  -mask "$DERIV/dwi_mask.mif" \
  -select 500000 \
  -minlength 10 \
  -maxlength 250 \
  -cutoff 0.06 \
  -nthreads 12 \
  -force

tcksift "$DERIV/tracks_500k.tck" \
  "$DERIV/wm_fod.mif" \
  "$DERIV/tracks_sift.tck" \
  -term_number 100000 \
  -csv "$REPO/results/tables/tcksift_iterations.csv" \
  -out_mu "$REPO/results/tables/tcksift_mu.txt" \
  -nthreads 12 \
  -force

tckmap "$DERIV/tracks_sift.tck" "$DERIV/tdi_sift.mif" \
  -template "$DERIV/mean_b0.mif" \
  -precise \
  -nthreads 12 \
  -force

tckedit "$DERIV/tracks_sift.tck" "$DERIV/tracks_display_20k.tck" \
  -number 20000 \
  -force

echo "Pipeline completed."
