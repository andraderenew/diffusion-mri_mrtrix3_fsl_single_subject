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
