# Task Report — Rename Ignite to MyTemplate + Quality Pipeline

**Deliverable repo (public):** https://github.com/premmuthusame1-merp/MyTemplate
**Commit:** `5eb5db1 Rename app to MyTemplate and add quality pipeline` (57 files)
**Branch:** `master` (pushed, tracking `origin/master`, working tree clean)

## Objective

1. Take the provided Flask starter (Ignite) and turn it into a presentable SaaS starter named **MyTemplate**, renaming all user-facing branding.
2. Add a complete, repeatable quality pipeline: unit tests, browser UI tests, linting, security scanning, coverage, CI automation — with machine-readable artifacts.
3. Commit and push everything to a public GitHub repository.

---

## 1. Environment Setup

| Item | Value |
|---|---|
| OS | Windows 10 (AWS EC2, PowerShell 5.1) |
| Python | 3.12.10 (venv at `env\Scripts\python.exe`) |
| Git | repository cloned from `https://github.com/Sumukh/Ignite.git` (upstream, branch `master`) |
| Tools | ruff, bandit, pytest, pytest-cov, pytest-junitxml, Playwright (chromium) |

- Created the virtual environment and installed `requirements.txt`.
- Removed unrelated leftover files (Rails/AWS artifacts) not part of the starter.
- Established the runbook (`AGENTS.md`) with local-dev commands (resetdb, server, test) and seed logins (`user@example.com`/`test`, `admin@example.com`/`admin`).

## 2. Baseline Verification

- Fixed `TestConfig` in `appname/settings.py`: `tempfile.NamedTemporaryFile()` held a file lock on Windows, breaking test DB creation → replaced with `tempfile.mkstemp()`.
- Ran the original suite: **102 tests passed** — the starter's baseline was healthy before any changes.

## 3. Rename: Ignite → MyTemplate

Renamed every **user-facing** occurrence; technical slot names (`appname`, `APPNAME_ENV`) stayed untouched.

### Application code
- `appname/services/branding.py` — product name, domains (`mytemplate.com`), static asset paths (`/static/public/mytemplate/*`).
- `appname/settings.py` — `MAIL_DEFAULT_SENDER` domain.
- `appname/controllers/auth.py`, `appname/controllers/oauth/google.py` — flash messages ("Welcome to MyTemplate.").
- `appname/mailers/__init__.py`, `auth.py`, `notification.py`, `store.py` — subject/display names.
- `appname/templates/` — lander index/terms, tabler header/footer, base templates (favicon paths), store product page, email base + purchase receipt.
- `app.json`, `.gitignore`, `README.md` (full rewrite), `AGENTS.md`, `AGENT_QUICKSTART.md`, `documentation/dokku.md`.

### Static assets (`git mv` to preserve history)
- `appname/static/public/ignite/` → `appname/static/public/mytemplate/`:
  - `mytemplate-icon.svg/.png`, `mytemplate-logo.svg` (wordmark redrawn, `font-size: 27`).
  - Removed obsolete raster logo @1x/@2x PNGs.
  - Regenerated the `demo-1.png` hero screenshot with a real Playwright browser session at the new branding.

### Intentional exceptions
- Upstream attribution links (github.com/sumukh/ignite, license) are **kept on purpose**; only product-facing branding was renamed.

## 4. Tests

### New unit tests — `tests/test_branding.py` (4 tests)
- Landing page renders new brand.
- Login page renders new brand.
- Signup page renders new brand.
- Signup flow welcomes the user with the new brand ("Welcome to MyTemplate.").

### New Playwright UI tests — `tests/ui/` (4 tests, chromium)
- `conftest.py`: session-scoped `live_server` fixture (self-starts the Flask dev server, `server_url` fixture, 60 s default timeout).
- `test_ui_flow.py`:
  - Landing page shows MyTemplate branding.
  - Signup flow lands on the dashboard.
  - Login with seeded account reaches the dashboard.
  - Login rejects a wrong password.

### Selector fixes during development
- Used robust selectors (`div.nav-header`, `get_by_label(..., exact=True)`, button `Sign Up`) to avoid ambiguity after branding changes.

## 5. Linting — Ruff

Configured in `pyproject.toml`: rules `E`, `F`; `line-length = 120`.

Fixes applied (all **real** issues — no blanket ignores):
- Removed unused imports across `appname/api/`, `appname/controllers/dashboard/files.py`, `dashboard/team.py`, `settings.py`, `webhooks/stripe.py`, `oauth/__init__.py` (kept re-export with `noqa`), `services/branding.py`, `services/stripe.py` (dropped dead `urllib.parse.unquote`).
- Fixed duplicate `stripe` import in `controllers/settings.py`.
- Renamed misleading `chunks(l, n)` → `chunks(seq, n)` in `appname/mailers/__init__.py` support code.
- `models/__init__.py` bare-except marked with targeted `noqa: E722`.
- Removed unused import in `tests/test_team.py`.

**Result: ruff 0 errors.**

## 6. Security — Bandit

Two real high-severity findings, both **fixed in code** (not suppressed):

| Finding | Fix |
|---|---|
| `B201` — `manage.py` ran the dev server with `debug=True` hard-coded | `debug=app.config.get('DEBUG', False)` — debug now config-driven |
| `B324` — MD5 used in `appname/services/security.py` | Switched to `hashlib.sha256` |

**Result: bandit 0 issues.**

## 7. Quality Pipeline

### `Makefile` (POSIX: CI, macOS, Linux, WSL)
- Targets: `setup`, `deps`, `test`, `ui-test`, `lint`, `security`, `ci` (full pipeline), `reports`, `clean`, plus legacy `agent-*` targets.
- Everything writes machine-readable artifacts into `reports/`.

### `scripts/ci.ps1` (native Windows equivalent)
- `-Step lint|security|test|ui-test|ci` parameter.
- Fixed two bugs during development: a PowerShell `$Args` automatic-variable collision (renamed to `$ArgsList`) and a duplicated `-m pytest` invocation.
- Produces the same artifacts as `make ci`.

### `.github/workflows/quality.yml` (GitHub Actions)
- Replaces the starter's `flask-pytest.yml`.
- Triggers: push + pull request on `ubuntu-latest`.
- Runs `make lint`, `make security`, `make test`, `make ui-test`, `make reports` and uploads `reports/` as the `quality-reports` artifact.

## 8. Artifacts (all in `reports/`, git-ignored)

| File | Contents |
|---|---|
| `junit.xml` | Unit test results (JUnit XML) |
| `ui-junit.xml` | Playwright UI test results (JUnit XML) |
| `coverage.xml` | Coveralls-format coverage report |
| `reports/html/` | HTML coverage report |
| `ruff.json` | Ruff findings (machine-readable — `[]` = clean) |
| `bandit.json` | Bandit findings (machine-readable) |
| `test-results/` | Playwright trace/video artifacts |

## 9. Verification — Full Pipeline Run (Windows)

Run via `scripts\ci.ps1`:

| Check | Result |
|---|---|
| Unit tests (pytest) | **106/106 passed** (180.6 s), 0 errors, 0 skipped |
| UI tests (Playwright, chromium) | **4/4 passed** (41.6 s) |
| Line coverage | **87.38 %** (1,295 / 1,482 lines) |
| Branch coverage | 74.78 % (169 / 226 branches) |
| Ruff (E, F) | **0 issues** |
| Bandit | **0 issues** (2 real findings fixed, 0 suppressed) |
| Working tree | Clean |

## 10. Git & Delivery

- Single commit `5eb5db1` — "Rename app to MyTemplate and add quality pipeline" (57 files) includes: branding rename, tests, lint/security fixes, Makefile, `scripts/ci.ps1`, GitHub Actions workflow, rewritten README/docs.
- Repository created at `https://github.com/premmuthusame1-merp/MyTemplate` (**public**), `origin` repointed from upstream, branch `master` pushed with upstream tracking.
- Confirmed in sync: `git push --dry-run` reports "up to date"; remote `master` == local `5eb5db1`.

## How to Reproduce

```bash
# Linux/macOS/WSL
make ci                        # full pipeline: lint -> security -> tests -> UI tests -> reports

# Windows
powershell -ExecutionPolicy Bypass -File scripts\ci.ps1

# Local dev
python3 -m venv env && source env/bin/activate
pip install -r requirements.txt
APPNAME_ENV=dev python manage.py resetdb
FLASK_APP=manage flask --debug run   # http://localhost:5000
```

Coverage HTML report, JUnit XMLs, and lint/security JSONs are then in `reports/`; CI run history is visible in the Actions tab of the repository.