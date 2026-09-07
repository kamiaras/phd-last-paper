# arXiv submission preparation

This worktree prepares the second arXiv revision from the latest manuscript on `tac-ieee`. Preparing these files does not submit the paper to arXiv.

## Local version history

- `arxiv-v1`: previous preparation snapshot at `97caf7a`.
- `arxiv-v2`: updated manuscript incorporating `290f21e` (infinite-memory SDAC comparison policies) and `72f436f` (language and mathematical presentation), with the preprint header retained and the PDF and source package rebuilt.

These tags identify local preparation snapshots. The repository does not record which files were uploaded to arXiv.

## Files and rebuild

From this worktree, run:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File scripts/prepare-arxiv.ps1
```

- Upload: `output/arxiv-source.zip`.
- Local PDF preview: `fresh_rewrite.pdf`.
- Main source: `fresh_rewrite.tex`.
- Compiler: pdfLaTeX.

The ZIP contains only `fresh_rewrite.tex`, `ref.bib`, and a freshly generated `fresh_rewrite.bbl`. Historical sources, local build files, extra files, and the preview PDF are excluded. The manuscript retains the IEEE journal format. See the official [submission instructions](https://info.arxiv.org/help/submit/index.html) and [TeX/LaTeX source guidance](https://info.arxiv.org/help/submit_tex.html).

## Submission metadata

**Title:** Online Constrained Control of Storage Systems via Simplex Disturbance-Action Policies

**Authors, in order:** Kamiar Asgari; Michael J. Neely

**Affiliation:** Department of Electrical and Computer Engineering, University of Southern California, Los Angeles, CA 90089 USA

**Corresponding author:** Kamiar Asgari (`kamiaras@usc.edu`). Michael J. Neely: `mjneely@usc.edu`.

**Recommended primary category:** `eess.SY` — Systems and Control. See the [arXiv category taxonomy](https://arxiv.org/category_taxonomy).

**Journal reference:** Leave blank.

**DOI:** Leave blank.

**Comments:** Leave blank unless the authors choose a factual note. Do not describe the paper as submitted to or accepted by TAC.

**Abstract** (matches the updated manuscript; only emphasis markup and line breaks are removed):

```text
We study online control of a scalar storage system with nonnegative adversarial resource arrivals and state-dependent action constraints. The adversarial, time-varying cost depends on both state and action. At each time, the controller selects a feasible action before the current resource arrival and cost are revealed. To handle the coupling between feasibility and online learning, we introduce Simplex Disturbance-Action Control (SDAC), whose policies have $H$ nonnegative parameters summing to at most one. Every fixed SDAC policy is feasible by construction. Our online SDAC controller updates these parameters using entropic online mirror descent while preserving feasibility along the time-varying trajectory. We prove a regret bound of $O\!\left(\sqrt{T\log(H+1)}\right)$ relative to the best fixed SDAC policy and a minimax lower bound showing that the dependence on $T$ is tight. We also introduce infinite-memory SDAC policies, which include every feasible fixed-fraction policy. SDAC policies approximate this class with an error that decreases geometrically with $H$. For a suitable choice $H=\Theta(\log T)$, the resulting regret against infinite-memory SDAC policies is $O\!\left(\sqrt{T\log\log T}\right)$. The framework applies to energy-harvesting batteries and other storage-constrained resource systems.
```

## Author decisions and final review

The authors must confirm the submission metadata, category, and license. The arXiv perpetual, non-exclusive license is one option for the authors to consider, subject to any funder requirements; no license has been selected here. See the official [arXiv license guidance](https://info.arxiv.org/help/license/index.html).

After uploading the ZIP, review the PDF compiled by arXiv, including equations, references, page breaks, title, and authors. The local preview does not replace that review. Complete the final submission only after the authors confirm the metadata and license and approve the compiled PDF.
