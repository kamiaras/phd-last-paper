# Simulation code

Experiments for `fresh_rewrite.tex`. Source code lives here; generated figures go to `../images/control/`.

## Layout

| File | Purpose |
|------|---------|
| `run_experiments.py` | Entry point: run simulations and regenerate figures |
| `env.py` | Dynamics, arrivals, costs |
| `egpc.py` | EGPC / SDAC online algorithm |
| `plot_results.py` | Plotting; writes PNGs under `../images/control/` |

## Setup

```bash
cd sim
python -m venv .venv
.venv\Scripts\activate        # Windows
pip install -r requirements.txt
```

## Run

```bash
python run_experiments.py
```

Figures are written to `images/control/` (paths match `\includegraphics{images/control/...}` in the manuscript).
