#!/usr/bin/env bash
set -euo pipefail

REPO="$HOME/github/diffusion-mri_mrtrix3_fsl_single_subject"
TAG="v1.0.0"
TITLE="v1.0.0 — Complete single-subject diffusion MRI workflow"

cd "$REPO"

git pull --ff-only

if [[ -n "$(git status --porcelain)" ]]; then
  echo "ERROR: el repositorio tiene cambios locales pendientes."
  git status --short
  exit 1
fi

command -v gh >/dev/null 2>&1 || {
  echo "ERROR: GitHub CLI no está instalado."
  exit 1
}

gh auth status >/dev/null 2>&1 || {
  echo "ERROR: inicia sesión primero con: gh auth login"
  exit 1
}

if gh release view "$TAG" >/dev/null 2>&1; then
  echo "La release $TAG ya existe."
  gh release view "$TAG"
  exit 0
fi

gh release create "$TAG" \
  --target main \
  --title "$TITLE" \
  --notes-file - <<'EOF'
## Initial public release

Complete reproducible single-subject diffusion MRI workflow using MRtrix3 and FSL.

### Included

- MP-PCA denoising
- Gibbs-ringing correction
- Motion, eddy-current, and outlier correction with FSL Eddy
- Diffusion tensor fitting
- FA, MD, AD, and RD maps
- Single-shell constrained spherical deconvolution
- Probabilistic iFOD2 whole-brain tractography
- SIFT filtering
- Track-density imaging
- Automated MRview quality-control figures
- EddyQC report
- Quantitative TSV and CSV outputs
- Reproducible Bash pipeline
- Methods, results, environment, citation metadata, and MIT license

### Main tractography outputs

- Initial tractogram: 500,000 streamlines
- SIFT-filtered tractogram: 189,356 streamlines
- Visualization subset: 20,000 streamlines
- SIFT μ: 0.0295905

### Important limitation

The acquisition did not include reverse phase-encoding data. Therefore, the workflow used `-rpe_none`, and TOPUP-based susceptibility distortion correction was not possible.

### Data

Public MPI-LEMON diffusion MRI data, subject `sub-010142`, session `ses-01`.
Raw imaging data and large derivatives are excluded from Git.
EOF

echo
echo "Release creada correctamente:"
gh release view "$TAG" --json url --jq '.url'
