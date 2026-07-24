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
| FA | 0.242333 | 0.187218755 |
| MD | 0.00108871 mm²/s | 0.000789097568 mm²/s |
| AD | 0.00132175 mm²/s | — |
| RD | 0.000972186 mm²/s | — |

These are whole-brain descriptive values computed inside the DWI mask. They should not be interpreted as normative measurements.

## Tractography

| Measure | Value |
|---|---:|
| Initial streamlines | 500000 |
| SIFT-filtered streamlines | 189356 |
| Display subset | 20000 |
| SIFT μ | 0.0295905 |
| Algorithm | iFOD2 |
| Minimum length | 10 mm |
| Maximum length | 250 mm |
| FOD cutoff | 0.06 |

The requested SIFT termination target was 100,000 streamlines, but the completed output contained 189356 streamlines. The repository reports the actual count measured from the tractogram rather than inferring it from the target parameter.

## Interpretation boundaries

This project demonstrates a reproducible technical workflow rather than a clinical or population-level analysis. Tractography streamlines are model-derived trajectories and should not be interpreted as direct proof of anatomical connections.
