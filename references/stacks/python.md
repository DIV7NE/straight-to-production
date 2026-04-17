# Python Stack Reference (v1.0)

**Use when:** `.stp/state/stack.json` has `"primary": "python"`. Auto-loaded by `/stp:build`, `/stp:think`, `/stp:debug`.

## Detection markers
Files whose presence indicates this stack (detect-stack.sh scans for these):
- `pyproject.toml`, `setup.py`, `setup.cfg`, `requirements.txt`
- `manage.py` (Django), `app.py` or `main.py` with `from fastapi` / `from flask`
- `.python-version`, `Pipfile`, `poetry.lock`
- (secondary) `Dockerfile` with `FROM python:*`, `gunicorn.conf.py`, `uvicorn` in requirements

## Commands
- **test:** `pytest` (or `python -m pytest -v`)
- **build:** `pip install -e .` (library) or `python -m build` (distribution)
- **lint:** `ruff check .`
- **type-check:** `mypy .`
- **format:** `black .` (or `ruff format .`)

## stack.json fields
```json
{
  "primary": "python",
  "ui": false,
  "test_cmd": "pytest",
  "build_cmd": "pip install -e .",
  "lint_cmd": "ruff check .",
  "type_cmd": "mypy ."
}
```

## Idiomatic patterns (what good code looks like)
- Type annotations on all public functions and class attributes — mypy strict mode passes clean
- Pydantic models for all data exchange boundaries (API request/response, config, env vars)
- `pathlib.Path` over `os.path` for all filesystem operations
- Context managers (`with`) for all resource acquisition — files, DB connections, HTTP sessions
- `pytest` fixtures for setup/teardown — never global test state or `setUp`/`tearDown` classes

## Common gotchas
- Mutable default arguments (`def f(items=[])`) share state across calls — use `None` and create inside
- Bare `except Exception` swallows everything including `KeyboardInterrupt` and `SystemExit` — catch specific exceptions
- Django ORM N+1 queries are invisible in dev but destroy production — use `select_related`/`prefetch_related`
- FastAPI dependency injection is lazy by default — missing a `Depends` import silently uses wrong scope
- `datetime.utcnow()` is deprecated in Python 3.12+ and timezone-naive — use `datetime.now(timezone.utc)`

## Opus 4.7 prompt adjustments (inject when stack matches)
- "Never use bare `except Exception` — catch specific exception types. Never swallow exceptions silently."
- "All public APIs must have complete type annotations. Run mypy before considering any function done."

## Anti-slop patterns for this stack
- `except Exception: pass` — slop (swallowed errors hide real failures)
- `# TODO: add types` — slop (annotate now, not later)
- `print(f"DEBUG: {secret}")` — slop (never print secrets; use structured logging)
- `time.sleep()` in test code — slop (use mocks or `freezegun` for time-dependent tests)
- `random.seed()` absent in ML/simulation tests — slop (non-reproducible tests are noise)

## Companion plugins / MCP servers
- **Context7** — pull live docs for FastAPI, Django, SQLAlchemy, Pydantic, pytest
- **Tavily** — research Python security advisories, packaging patterns, deployment configs

## References (external)
- Python packaging: https://packaging.python.org/en/latest/
- Google Python Style Guide: https://google.github.io/styleguide/pyguide.html
