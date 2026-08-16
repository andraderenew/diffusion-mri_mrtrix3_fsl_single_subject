#!/usr/bin/env bash
set -euo pipefail

REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
: "${WORK:?Set WORK to the external DWI work directory}"
DERIV="${DERIV:-$WORK/derivatives}"

mkdir -p "$REPO/reports" "$REPO/results/figures" "$REPO/results/tables"



TRACKS_INITIAL="$DERIV/tracks_500k.tck"
TRACKS_SIFT="${TRACKS_SIFT:-$DERIV/tracks_sift.tck}"
if [[ ! -f "$TRACKS_SIFT" && -f "$DERIV/tracks_sift_189k.tck" ]]; then
  TRACKS_SIFT="$DERIV/tracks_sift_189k.tck"
fi

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
  $'display_streamlines\t800' \
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
