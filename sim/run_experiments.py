"""Run simulations and regenerate experiment figures."""

from pathlib import Path

# Output directory for LaTeX figures (repo root / images / control)
FIGURES_DIR = Path(__file__).resolve().parent.parent / "images" / "control"


def main() -> None:
    FIGURES_DIR.mkdir(parents=True, exist_ok=True)
    (FIGURES_DIR / "kappa0.1").mkdir(exist_ok=True)
    (FIGURES_DIR / "kappa0.4").mkdir(exist_ok=True)

    # TODO: import env, egpc, plot_results; run experiments; save figures to FIGURES_DIR
    raise NotImplementedError("Simulation not implemented yet.")


if __name__ == "__main__":
    main()
