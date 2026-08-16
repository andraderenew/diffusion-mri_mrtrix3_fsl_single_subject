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

## Tensor validity QC

A physical-plausibility audit identified voxels with FA > 1 and/or negative MD, AD, or RD. The union of these voxels represented 0.000149642 of the DWI mask, or approximately 0.015%; 99.985% of mask voxels passed these criteria.

Recomputing the mean metrics after excluding those voxels changed FA by 0.0491%, MD by 0.0138%, AD by 0.0068%, and RD by 0.0190%. Because every change was below 0.05%, the primary results above remain the reproducible whole-DWI-mask summaries. The validity fractions and sensitivity values are retained in `results/tables/table3_tensor_validity_qc.tsv` and `results/tables/table4_dti_sensitivity.tsv`.

## Tractography

| Measure | Value |
|---|---:|
| Initial streamlines | 500000 |
| SIFT-filtered streamlines | 189356 |
| Display subset | 800 |
| SIFT μ | 0.0295905 |
| Algorithm | iFOD2 |
| Minimum length | 10 mm |
| Maximum length | 250 mm |
| FOD cutoff | 0.06 |

The requested SIFT termination target was 100,000 streamlines. The completed historical run terminated at 189356 streamlines; the final recorded SIFT iteration removed no additional streamlines. The repository therefore reports the actual output count and SIFT μ rather than treating the requested target as achieved.

The final whole-brain tractography figure uses an 800-streamline display-only subset for visual clarity. The scientific SIFT result remains the full 189356-streamline tractogram. A track-density image is retained as a derived analysis output but is not used as a primary static portfolio figure.

## Interpretation boundaries

This project demonstrates a reproducible technical workflow rather than a clinical or population-level analysis. Tractography streamlines are model-derived trajectories and should not be interpreted as direct proof of anatomical connections.
