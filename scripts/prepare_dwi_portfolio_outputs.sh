#!/usr/bin/env bash
set -euo pipefail

WORK="/media/andraderenew/Elements/neuroimaging/diffusion-mri_mrtrix3_fsl_single_subject"
DERIV="$WORK/derivatives"
REPO="$HOME/github/diffusion-mri_mrtrix3_fsl_single_subject"

mkdir -p "$REPO/reports" "$REPO/results/figures" "$REPO/results/tables"

if [[ -f "$DERIV/tracks_sift_100k.tck" && ! -f "$DERIV/tracks_sift_189k.tck" ]]; then
  mv "$DERIV/tracks_sift_100k.tck" "$DERIV/tracks_sift_189k.tck"
fi

if [[ -f "$DERIV/tdi_sift_100k.mif" && ! -f "$DERIV/tdi_sift_189k.mif" ]]; then
  mv "$DERIV/tdi_sift_100k.mif" "$DERIV/tdi_sift_189k.mif"
fi

TRACKS_INITIAL="$DERIV/tracks_500k.tck"
TRACKS_SIFT="$DERIV/tracks_sift_189k.tck"

for file in "$TRACKS_INITIAL" "$TRACKS_SIFT"; do
  if [[ ! -f "$file" ]]; then
    echo "ERROR: falta $file"
    exit 1
  fi
done

INITIAL_COUNT="$(tckinfo "$TRACKS_INITIAL" -count 2>/dev/null | awk '/actual count in file:/ {print $5}')"
SIFT_COUNT="$(tckinfo "$TRACKS_SIFT" -count 2>/dev/null | awk '/actual count in file:/ {print $5}')"

SIFT_MU="NA"
if [[ -f "$REPO/results/tables/tcksift_mu.txt" ]]; then
  SIFT_MU="$(tr -d '[:space:]' < "$REPO/results/tables/tcksift_mu.txt")"
fi

printf '%s\n' \
  $'measure\tvalue' \
  $'initial_streamlines\t'"$INITIAL_COUNT" \
  $'sift_streamlines\t'"$SIFT_COUNT" \
  $'display_streamlines\t20000' \
  $'sift_mu\t'"$SIFT_MU" \
  $'algorithm\tiFOD2' \
  $'minimum_length_mm\t10' \
  $'maximum_length_mm\t250' \
  $'fod_cutoff\t0.06' \
  > "$REPO/results/tables/table2_tractography_summary.tsv"

if [[ -f "$DERIV/eddy_qc/quad/qc.pdf" ]]; then
  cp -f "$DERIV/eddy_qc/quad/qc.pdf" \
    "$REPO/reports/eddy_qc_sub-010142.pdf"
fi

if [[ -f "$DERIV/eddy_qc/quad/avg_b0.png" ]]; then
  cp -f "$DERIV/eddy_qc/quad/avg_b0.png" \
    "$REPO/results/figures/fig1_eddy_qc_avg_b0.png"
fi

if [[ -f "$DERIV/eddy_qc/quad/avg_b1000.png" ]]; then
  cp -f "$DERIV/eddy_qc/quad/avg_b1000.png" \
    "$REPO/results/figures/fig2_eddy_qc_avg_b1000.png"
fi

echo "=== Tabla de tractografía ==="
cat "$REPO/results/tables/table2_tractography_summary.tsv"

echo
echo "=== Figuras EddyQC ==="
ls -lh "$REPO/results/figures"/fig1_eddy_qc_avg_b0.png \
       "$REPO/results/figures"/fig2_eddy_qc_avg_b1000.png 2>/dev/null || true

echo
echo "=== Informe EddyQC ==="
ls -lh "$REPO/reports/eddy_qc_sub-010142.pdf" 2>/dev/null || true
