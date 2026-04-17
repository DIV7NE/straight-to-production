# Data / ML Stack Reference (v1.0)

**Use when:** `.stp/state/stack.json` has `"primary": "data-ml"`. Auto-loaded by `/stp:build`, `/stp:think`, `/stp:debug`.

## Detection markers
Files whose presence indicates this stack (detect-stack.sh scans for these):
- `pyproject.toml` or `requirements.txt` containing `torch`, `tensorflow`, `jax`, `sklearn`, `pandas`, `numpy`
- `*.ipynb` Jupyter notebooks in the project root or `notebooks/` directory
- `dbt_project.yml` (dbt), `airflow_home/` or `dags/` directory (Airflow)
- (secondary) `mlflow.yml`, `.dvc/` (DVC), `wandb/` artifacts, `Makefile` with `train`/`evaluate` targets

## Commands
- **test:** `pytest tests/`
- **build:** `python -m build` (library) or `make train` (model training entrypoint)
- **lint:** `ruff check .`
- **type-check:** `mypy .`
- **format:** `black .` (or `ruff format .`)

## stack.json fields
```json
{
  "primary": "data-ml",
  "ui": false,
  "test_cmd": "pytest tests/",
  "build_cmd": "python -m build",
  "lint_cmd": "ruff check .",
  "type_cmd": "mypy ."
}
```

## Idiomatic patterns (what good code looks like)
- All experiments seeded: `random.seed(SEED)`, `np.random.seed(SEED)`, `torch.manual_seed(SEED)` — non-reproducible results are not results
- Data pipelines are pure functions that take a DataFrame/tensor and return a DataFrame/tensor — no side effects, no global state
- Train/val/test splits computed once and saved as artifacts — never recomputed from scratch mid-experiment
- Model artifacts versioned with DVC or MLflow — never committed as binary blobs to git
- Data validation at pipeline entry points with Great Expectations, Pandera, or manual schema checks — garbage in, garbage out is a bug

## Common gotchas
- Bare `except Exception` in a training loop silently catches CUDA OOM errors — catch specific exceptions and log GPU memory state
- Data leakage: applying `StandardScaler.fit_transform` on the full dataset before splitting leaks test statistics into training
- `df.iterrows()` on large DataFrames is O(n) Python loop — use vectorized operations or `df.apply` with `axis=1`
- `torch.no_grad()` missing in evaluation loop computes gradients unnecessarily, wasting memory and time
- Jupyter notebooks used for production pipelines cause import order and state-pollution bugs — refactor to `.py` modules before deployment

## Opus 4.7 prompt adjustments (inject when stack matches)
- "Seed all RNGs at the top of every script (`random`, `numpy`, `torch`, `tensorflow`). Non-reproducible experiments are not science."
- "Never catch bare `Exception` in a training or evaluation loop — catch specific exception types so CUDA errors, OOM, and data errors surface clearly."

## Anti-slop patterns for this stack
- `except Exception: pass` in training loops — slop (swallows CUDA OOM and data errors)
- Missing `random.seed()` / `torch.manual_seed()` — slop (non-reproducible)
- `df.iterrows()` on DataFrames > 10k rows — slop (use vectorized ops)
- Model weights committed to git — slop (use DVC or MLflow artifacts)
- `# TODO: validate data` — slop (validate at pipeline entry, always)

## Companion plugins / MCP servers
- **Context7** — pull live docs for PyTorch, scikit-learn, pandas, dbt, and Airflow
- **Tavily** — research dataset licensing, ML reproducibility best practices, and model deployment patterns

## References (external)
- Google ML best practices: https://developers.google.com/machine-learning/guides/rules-of-ml
- Pandas user guide: https://pandas.pydata.org/docs/user_guide/
