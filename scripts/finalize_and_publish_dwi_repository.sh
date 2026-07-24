#!/usr/bin/env bash
set -euo pipefail

REPO="$HOME/github/diffusion-mri_mrtrix3_fsl_single_subject"
WORK="/media/andraderenew/Elements/neuroimaging/diffusion-mri_mrtrix3_fsl_single_subject"
DERIV="$WORK/derivatives"
RAW="$WORK/data/raw/sub-010142/ses-01/dwi"
PUSH=false

if [[ "${1:-}" == "--push" ]]; then
  PUSH=true
fi

cd "$REPO"
mkdir -p docs scripts reports results/figures results/tables

required=(
  "results/figures/fig1_eddy_qc_avg_b0.png"
  "results/figures/fig2_eddy_qc_avg_b1000.png"
  "results/figures/fig3_fa_map.png"
  "results/figures/fig4_fod_orientation.png"
  "results/figures/fig5_whole_brain_tractography.png"
  "results/figures/fig6_track_density_image.png"
  "results/tables/table1_global_dti_metrics.tsv"
  "results/tables/table2_tractography_summary.tsv"
  "reports/eddy_qc_sub-010142.pdf"
  "env/TOOL_VERSIONS.md"
)

for file in "${required[@]}"; do
  if [[ ! -f "$file" ]]; then
    echo "ERROR: falta $REPO/$file"
    exit 1
  fi
done

value_from_table() {
  local table="$1"
  local key="$2"
  awk -F'\t' -v key="$key" '$1 == key {gsub(/[[:space:]]/, "", $2); print $2; exit}' "$table"
}

metric_from_table() {
  local metric="$1"
  local column="$2"
  awk -F'\t' -v metric="$metric" -v column="$column" '
    NR==1 {
      for (i=1; i<=NF; i++) if ($i==column) c=i
      next
    }
    $1==metric {
      gsub(/[[:space:]]/, "", $c)
      print $c
      exit
    }
  ' results/tables/table1_global_dti_metrics.tsv
}

FA_MEAN="$(metric_from_table fa mean)"
FA_MEDIAN="$(metric_from_table fa median)"
MD_MEAN="$(metric_from_table md mean)"
MD_MEDIAN="$(metric_from_table md median)"
AD_MEAN="$(metric_from_table ad mean)"
RD_MEAN="$(metric_from_table rd mean)"

INITIAL_STREAMLINES="$(value_from_table results/tables/table2_tractography_summary.tsv initial_streamlines)"
SIFT_STREAMLINES="$(value_from_table results/tables/table2_tractography_summary.tsv sift_streamlines)"
DISPLAY_STREAMLINES="$(value_from_table results/tables/table2_tractography_summary.tsv display_streamlines)"
SIFT_MU="$(value_from_table results/tables/table2_tractography_summary.tsv sift_mu)"

cat > README.md <<EOF
# Diffusion MRI: MRtrix3 + FSL single-subject workflow

Reproducible single-subject diffusion MRI workflow combining **MRtrix3** and **FSL** for preprocessing, diffusion tensor imaging, constrained spherical deconvolution, whole-brain tractography, SIFT filtering, quantitative summaries, and visual quality control.

## Dataset

- Public MPI-LEMON diffusion MRI data
- Subject: \`sub-010142\`
- Session: \`ses-01\`
- Matrix: \`128 × 128 × 88 × 67\`
- Resolution: \`1.71875 × 1.71875 × 1.7 mm\`
- Shells: 7 volumes near \`b=0\` and 60 directions near \`b=1000 s/mm²\`
- Phase-encoding direction: \`j-\`
- Total readout time: \`0.04914 s\`

Raw imaging data and large derivatives are intentionally excluded from Git.

## Workflow

1. NIfTI, b-values, b-vectors, and JSON imported into MRtrix format.
2. MP-PCA denoising with \`dwidenoise\`.
3. Gibbs-ringing correction with \`mrdegibbs\`.
4. Motion, eddy-current, and outlier correction with \`dwifslpreproc\` and FSL Eddy.
5. Brain-mask generation with \`dwi2mask\`.
6. Tensor fitting and FA, MD, AD, and RD calculation.
7. Single-shell white-matter response estimation and CSD.
8. Whole-brain probabilistic iFOD2 tractography.
9. SIFT filtering and track-density imaging.
10. Automated QC figures and tabular summaries.

The acquisition does not contain reverse phase-encoding data. Therefore, preprocessing used \`-rpe_none\`; susceptibility distortion correction with TOPUP was not possible.

## Main quantitative results

| Measure | Result |
|---|---:|
| Mean FA | ${FA_MEAN} |
| Median FA | ${FA_MEDIAN} |
| Mean MD | ${MD_MEAN} mm²/s |
| Median MD | ${MD_MEDIAN} mm²/s |
| Mean AD | ${AD_MEAN} mm²/s |
| Mean RD | ${RD_MEAN} mm²/s |
| Initial tractogram | ${INITIAL_STREAMLINES} streamlines |
| SIFT-filtered tractogram | ${SIFT_STREAMLINES} streamlines |
| Display tractogram | ${DISPLAY_STREAMLINES} streamlines |
| SIFT μ | ${SIFT_MU} |

Global tensor summaries were calculated inside the whole-brain DWI mask and are descriptive, not normative or diagnostic.

## Quality-control figures

### EddyQC mean b=0

![EddyQC mean b0](results/figures/fig1_eddy_qc_avg_b0.png)

### EddyQC mean b=1000

![EddyQC mean b1000](results/figures/fig2_eddy_qc_avg_b1000.png)

### Fractional anisotropy

![FA map](results/figures/fig3_fa_map.png)

### Fiber orientation distributions

![FOD orientation](results/figures/fig4_fod_orientation.png)

### Whole-brain tractography

![Whole-brain tractography](results/figures/fig5_whole_brain_tractography.png)

### Track-density image

![Track-density image](results/figures/fig6_track_density_image.png)

## Repository structure

\`\`\`text
.
├── docs/
│   ├── METHODS.md
│   └── RESULTS.md
├── env/
│   └── TOOL_VERSIONS.md
├── reports/
│   └── eddy_qc_sub-010142.pdf
├── results/
│   ├── figures/
│   └── tables/
└── scripts/
    ├── run_dwi_pipeline.sh
    ├── prepare_dwi_portfolio_outputs.sh
    └── make_mrview_figures.sh
\`\`\`

## Reproduction

Review and adapt the path variables at the beginning of:

\`\`\`bash
scripts/run_dwi_pipeline.sh
\`\`\`

Then run:

\`\`\`bash
chmod +x scripts/run_dwi_pipeline.sh
./scripts/run_dwi_pipeline.sh
\`\`\`

The script expects the raw DWI NIfTI, b-value, b-vector, and JSON files in the external working directory documented in the script.

## Limitations

- Single subject.
- Single-shell diffusion acquisition.
- No reverse phase-encoding acquisition for TOPUP.
- Whole-brain mask statistics combine multiple tissue classes.
- Tractography is model-dependent and does not demonstrate direct anatomical connectivity.
- Automated figures should still receive visual review before interpretation.

## Software environment

See [env/TOOL_VERSIONS.md](env/TOOL_VERSIONS.md).

## Author

**Rene Andrade Rey**  
ORCID: 0000-0001-5627-579X
EOF

cat > docs/METHODS.md <<'EOF'
# Methods

## Data

The analysis used the diffusion MRI acquisition from MPI-LEMON subject `sub-010142`, session `ses-01`. The image contained 67 volumes at approximately 1.7 mm isotropic spatial resolution. Gradient information consisted of seven volumes near b=0 and 60 diffusion-weighted directions near b=1000 s/mm². The BIDS metadata specified a phase-encoding direction of `j-` and a total readout time of 0.04914 seconds.

## Preprocessing

The NIfTI image, b-values, b-vectors, and JSON metadata were imported into MRtrix format. MP-PCA denoising was applied with `dwidenoise`, and the denoising residual was retained for QC. Gibbs-ringing correction was then performed with `mrdegibbs`.

Motion, eddy-current, and outlier correction were performed through `dwifslpreproc`, using FSL Eddy with outlier replacement (`--repol`). Because no reverse phase-encoding acquisition was available, preprocessing used `-rpe_none`. Consequently, TOPUP-based susceptibility distortion correction was not performed.

A mean b=0 image was generated from the corrected series, and a whole-brain DWI mask was estimated with `dwi2mask`.

## Diffusion tensor imaging

A diffusion tensor was fitted inside the DWI mask with `dwi2tensor`. Tensor-derived measures were calculated with `tensor2metric`:

- Fractional anisotropy (FA)
- Mean diffusivity (MD)
- Axial diffusivity (AD)
- Radial diffusivity (RD)
- Principal eigenvector

Whole-brain descriptive statistics were calculated within the DWI mask.

## Fiber-orientation modelling

A single-shell white-matter response function was estimated with the Tournier algorithm. Constrained spherical deconvolution was used to estimate white-matter fiber orientation distributions.

## Tractography

Whole-brain probabilistic tractography was generated with the iFOD2 algorithm and dynamic seeding. Parameters were:

- Initial target: 500,000 streamlines
- Minimum length: 10 mm
- Maximum length: 250 mm
- FOD cutoff: 0.06
- Brain-mask constraint
- 12 processing threads

SIFT filtering was applied to improve agreement between streamline densities and the FOD model. The resulting tractogram contained 189,356 streamlines. A 20,000-streamline subset was generated for visualization, and the SIFT-filtered tractogram was converted into a track-density image.

## Quality control

Quality control included:

- FSL EddyQC report
- Mean b=0 and mean b=1000 images
- FA overlay
- FOD orientation display
- Whole-brain tractography display
- Track-density image

The figures were generated automatically with MRview command-line capture options. Automated capture improves reproducibility but does not replace visual inspection.
EOF

cat > docs/RESULTS.md <<EOF
# Results

## Data integrity

The DWI image contained 67 volumes. The b-value file and each of the three b-vector rows also contained 67 entries, confirming consistency between the imaging and gradient files.

The imported MRtrix image retained:

- Matrix: 128 × 128 × 88 × 67
- Voxel size: 1.71875 × 1.71875 × 1.7 mm
- Seven volumes near b=0
- Sixty directions near b=1000 s/mm²

## Preprocessing

The preprocessing pipeline completed successfully and generated:

- Denoised DWI
- Noise map
- Denoising residual
- Gibbs-corrected DWI
- Eddy-corrected DWI
- Updated b-vectors and b-values
- EddyQC report and associated QC outputs

## Diffusion tensor metrics

| Metric | Mean | Median |
|---|---:|---:|
| FA | ${FA_MEAN} | ${FA_MEDIAN} |
| MD | ${MD_MEAN} mm²/s | ${MD_MEDIAN} mm²/s |
| AD | ${AD_MEAN} mm²/s | — |
| RD | ${RD_MEAN} mm²/s | — |

These are whole-brain descriptive values computed inside the DWI mask. They should not be interpreted as normative measurements.

## Tractography

| Measure | Value |
|---|---:|
| Initial streamlines | ${INITIAL_STREAMLINES} |
| SIFT-filtered streamlines | ${SIFT_STREAMLINES} |
| Display subset | ${DISPLAY_STREAMLINES} |
| SIFT μ | ${SIFT_MU} |
| Algorithm | iFOD2 |
| Minimum length | 10 mm |
| Maximum length | 250 mm |
| FOD cutoff | 0.06 |

The requested SIFT termination target was 100,000 streamlines, but the completed output contained ${SIFT_STREAMLINES} streamlines. The repository reports the actual count measured from the tractogram rather than inferring it from the target parameter.

## Interpretation boundaries

This project demonstrates a reproducible technical workflow rather than a clinical or population-level analysis. Tractography streamlines are model-derived trajectories and should not be interpreted as direct proof of anatomical connections.
EOF

cat > scripts/run_dwi_pipeline.sh <<'EOF'
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
EOF

chmod +x scripts/run_dwi_pipeline.sh

cat > CITATION.cff <<'EOF'
cff-version: 1.2.0
message: "Please cite this repository when reusing the workflow."
title: "Diffusion MRI: MRtrix3 and FSL single-subject workflow"
version: 1.0.0
date-released: 2026-07-24
authors:
  - family-names: "Andrade Rey"
    given-names: "Rene"
    orcid: "https://orcid.org/0000-0001-5627-579X"
repository-code: "https://github.com/andraderenew/diffusion-mri_mrtrix3_fsl_single_subject"
license: MIT
keywords:
  - diffusion MRI
  - DTI
  - tractography
  - MRtrix3
  - FSL
  - neuroimaging
EOF

cat > LICENSE <<'EOF'
MIT License

Copyright (c) 2026 Rene Andrade Rey

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
EOF

git add .
if git diff --cached --quiet; then
  echo "No hay cambios nuevos para confirmar."
else
  git commit -m "Complete diffusion MRI preprocessing, DTI, CSD, tractography, QC, and documentation"
fi

if [[ "$PUSH" == true ]]; then
  command -v gh >/dev/null 2>&1 || {
    echo "ERROR: GitHub CLI no está instalado."
    exit 1
  }

  gh auth status >/dev/null 2>&1 || {
    echo "ERROR: GitHub CLI no tiene una sesión iniciada. Ejecuta: gh auth login"
    exit 1
  }

  if ! git remote get-url origin >/dev/null 2>&1; then
    gh repo create andraderenew/diffusion-mri_mrtrix3_fsl_single_subject \
      --public \
      --source=. \
      --remote=origin \
      --description "Single-subject diffusion MRI workflow using MRtrix3 and FSL: Eddy, DTI, CSD, tractography, SIFT, QC, and reproducible scripts."
  fi

  git push -u origin main

  gh repo edit andraderenew/diffusion-mri_mrtrix3_fsl_single_subject \
    --add-topic neuroimaging \
    --add-topic diffusion-mri \
    --add-topic dti \
    --add-topic tractography \
    --add-topic mrtrix3 \
    --add-topic fsl

  echo
  echo "Publicado:"
  echo "https://github.com/andraderenew/diffusion-mri_mrtrix3_fsl_single_subject"
else
  echo
  echo "Repositorio finalizado localmente."
  echo "Para publicarlo, ejecuta el mismo script con: --push"
fi

echo
git status --short --branch
