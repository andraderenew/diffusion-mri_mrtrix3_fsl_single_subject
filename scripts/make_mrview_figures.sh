#!/usr/bin/env bash
set -euo pipefail

REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
: "${WORK:?Set WORK to the external DWI work directory}"

DERIV="${DERIV:-$WORK/derivatives}"
OUT="${OUT:-$REPO/results/figures}"
TMP="$OUT/.mrview_capture_tmp"

mkdir -p "$OUT" "$TMP"
rm -f "$TMP"/*.png "$TMP"/*.tck 2>/dev/null || true

required=(
  "$DERIV/mean_b0.mif"
  "$DERIV/fa.mif"
  "$DERIV/wm_fod.mif"
)

for file in "${required[@]}"; do
  if [[ ! -f "$file" ]]; then
    echo "ERROR: missing required file:"
    echo "  $file"
    exit 1
  fi
done

TRACKS_SIFT="${TRACKS_SIFT:-$DERIV/tracks_sift.tck}"

if [[ ! -f "$TRACKS_SIFT" && -f "$DERIV/tracks_sift_189k.tck" ]]; then
  TRACKS_SIFT="$DERIV/tracks_sift_189k.tck"
fi

if [[ ! -f "$TRACKS_SIFT" ]]; then
  echo "ERROR: SIFT tractogram not found"
  exit 1
fi

echo "=== Figure 3: three-view FA on mean-b0 anatomy ==="

rm -f "$TMP"/fa_*.png 2>/dev/null || true

mrview "$DERIV/mean_b0.mif" \
  -voxel 64,64,44 \
  -fov 170 \
  -focus 0 \
  -noannotations \
  -size 1000,1000 \
  -overlay.load "$DERIV/fa.mif" \
  -overlay.opacity 0.70 \
  -overlay.intensity 0,0.8 \
  -overlay.threshold_min 0.15 \
  -capture.folder "$TMP" \
  -capture.prefix fa_ \
  -plane 0 \
  -capture.grab \
  -plane 1 \
  -capture.grab \
  -plane 2 \
  -capture.grab \
  -exit

sleep 3

FA1="$(find "$TMP" -maxdepth 1 -type f -name "fa_*.png" | sort | sed -n "1p")"
FA2="$(find "$TMP" -maxdepth 1 -type f -name "fa_*.png" | sort | sed -n "2p")"
FA3="$(find "$TMP" -maxdepth 1 -type f -name "fa_*.png" | sort | sed -n "3p")"

if [[ -z "$FA1" || -z "$FA2" || -z "$FA3" ]]; then
  echo "ERROR: incomplete FA captures"
  exit 1
fi

python3 -c "from PIL import Image; ims=[Image.open(p).convert(\"RGB\") for p in [\"$FA1\",\"$FA2\",\"$FA3\"]]; W=sum(i.width for i in ims); H=max(i.height for i in ims); out=Image.new(\"RGB\",(W,H)); x=0; [(out.paste(im,(sum(j.width for j in ims[:k]),0))) for k,im in enumerate(ims)]; out.save(\"$OUT/fig3_fa_map.png\")"

echo "OK: $OUT/fig3_fa_map.png"

echo "=== Figure 4: FOD orientation ==="

rm -f "$TMP"/fod_*.png 2>/dev/null || true

mrview "$DERIV/mean_b0.mif" \
  -plane 2 \
  -voxel 64,64,55 \
  -fov 95 \
  -focus 0 \
  -noannotations \
  -size 900,900 \
  -odf.load_sh "$DERIV/wm_fod.mif" \
  -capture.folder "$TMP" \
  -capture.prefix fod_ \
  -capture.grab \
  -exit

sleep 2

FOD="$(find "$TMP" -maxdepth 1 -type f -name "fod_*.png" | sort | head -n 1)"

if [[ -z "$FOD" ]]; then
  echo "ERROR: FOD capture not generated"
  exit 1
fi

cp -f "$FOD" "$OUT/fig4_fod_orientation.png"

echo "OK: $OUT/fig4_fod_orientation.png"

echo "=== Figure 5: 800-streamline display subset ==="

tckedit \
  "$TRACKS_SIFT" \
  "$TMP/tracks_display_800.tck" \
  -number 800 \
  -force

rm -f "$TMP"/tracks_*.png 2>/dev/null || true

mrview "$DERIV/mean_b0.mif" \
  -mode 3 \
  -imagevisible 0 \
  -fov 185 \
  -focus 0 \
  -noannotations \
  -size 1200,1000 \
  -tractography.load "$TMP/tracks_display_800.tck" \
  -tractography.geometry lines \
  -tractography.thickness -0.7 \
  -tractography.opacity 0.70 \
  -capture.folder "$TMP" \
  -capture.prefix tracks_ \
  -capture.grab \
  -exit

sleep 3

TRACKS="$(find "$TMP" -maxdepth 1 -type f -name "tracks_*.png" | sort | head -n 1)"

if [[ -z "$TRACKS" ]]; then
  echo "ERROR: tractography capture not generated"
  exit 1
fi

cp -f "$TRACKS" "$OUT/fig5_whole_brain_tractography.png"

rm -rf "$TMP"

echo
echo "=== Final presentation figures generated ==="
ls -lh \
  "$OUT/fig3_fa_map.png" \
  "$OUT/fig4_fod_orientation.png" \
  "$OUT/fig5_whole_brain_tractography.png"
