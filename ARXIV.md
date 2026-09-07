# arXiv submission preparation

This version is being prepared for arXiv first. The paper has not yet been submitted to IEEE Transactions on Automatic Control (TAC). Preparing these files does not submit the paper to arXiv.

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

**Abstract** (copy the text below; the mathematics is unchanged):

```text
We study online control of a scalar storage system with nonnegative adversarial resource arrivals and state-dependent action constraints. The adversarial, time-varying cost depends on both the state and the action. At each time, the controller selects a feasible action before the current resource arrival and cost are revealed. To handle the resulting coupling between feasibility and online learning, we introduce Simplex Disturbance-Action Control (SDAC), a policy class specified by $H$ nonnegative parameters whose sum is at most one. The key feature of SDAC is that every fixed policy in the class is feasible by construction. Our online SDAC controller updates these parameters using entropic online mirror descent while preserving feasibility along the time-varying trajectory. We prove a regret bound of $O\!\left(\sqrt{T\log(H+1)}\right)$ relative to the best fixed SDAC policy and a minimax lower bound showing that the dependence on $T$ is tight. Moreover, SDAC geometrically approximates a decreasing-allocation policy class that spreads each arrival over time according to a common decreasing allocation sequence, a structure that arises in stochastic energy-harvesting control. With a suitable choice $H=\Theta(\log T)$, the resulting regret against the decreasing-allocation class is $O\!\left(\sqrt{T\log\log T}\right)$. The framework applies to energy-harvesting batteries and other storage-constrained resource systems.
```

## Author decisions and final review

The authors must confirm the submission metadata, category, and license. The arXiv perpetual, non-exclusive license is one option for the authors to consider, subject to any funder requirements; no license has been selected here. See the official [arXiv license guidance](https://info.arxiv.org/help/license/index.html).

After uploading the ZIP, review the PDF compiled by arXiv, including equations, references, page breaks, title, and authors. The local preview does not replace that review. Complete the final submission only after the authors confirm the metadata and license and approve the compiled PDF.
