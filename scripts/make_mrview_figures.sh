#!/usr/bin/env bash
set -euo pipefail

WORK="/media/andraderenew/Elements/neuroimaging/diffusion-mri_mrtrix3_fsl_single_subject"
DERIV="$WORK/derivatives"
REPO="$HOME/github/diffusion-mri_mrtrix3_fsl_single_subject"
OUT="$REPO/results/figures"
TMP="$OUT/.mrview_capture_tmp"

mkdir -p "$OUT" "$TMP"
rm -f "$TMP"/*.png 2>/dev/null || true

required=(
  "$DERIV/mean_b0.mif"
  "$DERIV/fa.mif"
  "$DERIV/wm_fod.mif"
  "$DERIV/tracks_display_20k.tck"
)

for file in "${required[@]}"; do
  if [[ ! -f "$file" ]]; then
    echo "ERROR: falta el archivo:"
    echo "  $file"
    exit 1
  fi
done

if [[ -f "$DERIV/tdi_sift_189k.mif" ]]; then
  TDI="$DERIV/tdi_sift_189k.mif"
elif [[ -f "$DERIV/tdi_sift_100k.mif" ]]; then
  TDI="$DERIV/tdi_sift_100k.mif"
else
  echo "ERROR: no encuentro la imagen TDI."
  exit 1
fi

capture() {
  local prefix="$1"
  local destination="$2"
  shift 2

  rm -f "$TMP/${prefix}"*.png 2>/dev/null || true

  mrview "$@" \
    -size 1200,900 \
    -capture.folder "$TMP" \
    -capture.prefix "$prefix" \
    -capture.grab \
    -exit

  sleep 2

  local captured
  captured="$(find "$TMP" -maxdepth 1 -type f -name "${prefix}*.png" -print -quit)"

  if [[ -z "$captured" ]]; then
    echo "ERROR: mrview no generó $destination"
    exit 1
  fi

  mv -f "$captured" "$OUT/$destination"
  echo "OK: $OUT/$destination"
}

echo "=== Figura 3: mapa FA ==="
capture \
  "fa_" \
  "fig3_fa_map.png" \
  "$DERIV/mean_b0.mif" \
  -plane 2 \
  -voxel 64,64,44 \
  -overlay.load "$DERIV/fa.mif" \
  -overlay.opacity 0.70 \
  -overlay.intensity 0,0.8 \
  -overlay.threshold_min 0.15

echo "=== Figura 4: orientaciones FOD ==="
capture \
  "fod_" \
  "fig4_fod_orientation.png" \
  "$DERIV/mean_b0.mif" \
  -plane 2 \
  -voxel 64,64,55 \
  -odf.load_sh "$DERIV/wm_fod.mif"

echo "=== Figura 5: tractografía ==="
capture \
  "tracks_" \
  "fig5_whole_brain_tractography.png" \
  "$DERIV/mean_b0.mif" \
  -mode 3 \
  -imagevisible 0 \
  -tractography.load "$DERIV/tracks_display_20k.tck"

echo "=== Figura 6: densidad de tractos ==="
capture \
  "tdi_" \
  "fig6_track_density_image.png" \
  "$DERIV/mean_b0.mif" \
  -plane 2 \
  -voxel 64,64,44 \
  -overlay.load "$TDI" \
  -overlay.opacity 0.80

rm -rf "$TMP"

echo
echo "=== Capturas terminadas ==="
ls -lh \
  "$OUT/fig3_fa_map.png" \
  "$OUT/fig4_fod_orientation.png" \
  "$OUT/fig5_whole_brain_tractography.png" \
  "$OUT/fig6_track_density_image.png"
