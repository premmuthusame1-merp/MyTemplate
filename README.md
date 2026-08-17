# MyTemplate for Flask

MyTemplate is a Flask starter application for building SaaS products. It is a renamed, tested rename of the
[Ignite for Flask](https://github.com/sumukh/ignite) scaffold and includes a repeatable quality pipeline
(unit tests, UI tests, linting, security scanning, and reporting) that runs locally and in GitHub Actions.

## Features

| Features                              | Status                                       | Details                                                                                    |
| ------------------------------------- | -------------------------------------------- | ------------------------------------------------------------------------------------------ |
| User Authentication                   | ✅                                           | User Login, Registration, Forgot Password, Email Confirmation                              |
| OAuth Login                           | ✅                                           | Login or Register with Google, Twitter, Facebook, etc.                                     |
| Teams/Groups                          | ✅                                           | Multi user teams & groups (with Invite Emails)                                             |
| User Export & Deletion Request        | ✅                                           | Allows users to export their data (for GDPR compliance)                                    |
| API                                   | ✅                                           | API (with user tokens) users to access data                                                |
| Stripe Product Checkout               | ✅                                           | One time item purchases with credit cards and receipts (using Stripe)                      |
| Heroku/Docker Deployment              | ✅                                           | Deployment instructions for some platforms. Works on AWS & Google Cloud                    |
| Send Emails                           | ✅                                           | Send email notifications from the application                                              |
| Admin Dashboard                       | ✅                                           | Admin dashboard to edit data                                                               |
| File Uploads                          | ✅                                           | File uploads to cloud storage providers                                                    |
| Basic Test Suite                      | ✅                                           | pytest unit tests + Playwright UI tests                                                    |
| Quality Pipeline                      | ✅                                           | Lint (Ruff), security scan (Bandit), coverage (pytest-cov), reports in `reports/`          |
| Tested on Windows, OSX, and Ubuntu    | ✅                                           | Using Python 3                                                                             |

## Setup (Local Development)

Requirements: Python 3.10+ and Google Chrome (for Playwright UI tests; Playwright can also
[install its own browser](https://playwright.dev/python/docs/browsers)).

```bash
# 1. Create a virtual environment and install dependencies (including dev tools)
python3 -m venv env
source env/bin/activate
pip install -r requirements.txt
pip install ruff bandit pytest-playwright playwright
playwright install chromium        # once, to download the browser used by UI tests

# 2. Seed a local SQLite database with starter users
APPNAME_ENV=dev ./manage.py resetdb

# 3. Run the app
FLASK_APP=manage flask --debug run
# or: ./manage.py server
```

Open `http://localhost:5000`. Seeded dev logins after `resetdb`:

- `user@example.com` / `test`
- `admin@example.com` / `admin`

### Local Secrets

To configure OAuth login and Stripe billing in development, set the environment variables in
`.env.local.sample`:

```bash
cp .env.local.sample .env.local
# Edit .env.local with your Stripe & Google test keys
source .env.local
FLASK_APP=manage flask --debug run
```

To change the application name in the UI, edit `appname/services/branding.py`.

## Quality Pipeline

Everything runs through `make`. The full pipeline is:

```bash
make ci
```

which runs, in order:

| Step                  | Command                 | Report artifact                                   |
| --------------------- | ----------------------- | ------------------------------------------------- |
| Backend unit tests    | `make test`             | `reports/junit.xml` (JUnit XML)                   |
| Coverage              | part of `make test`     | `reports/coverage.xml` (XML) + `reports/html/`    |
| UI tests (Playwright) | `make ui-test`          | `reports/ui/` (JSON, JUnit/HTML and screenshots)  |
| Static analysis       | `make lint`             | `reports/ruff.json` (machine-readable)            |
| Security scan         | `make security`         | `reports/bandit.json` (JSON)                     |

All reports are written to the `reports/` directory (git-ignored), so a completed build leaves a
single folder to review: `reports/`.

To run a single step locally:

```bash
make test        # pytest + coverage (unit tests + JUnit XML report)
make ui-test     # Playwright UI tests against the running app
make lint        # Ruff static analysis (JSON output to reports/)
make security    # Bandit security scan (JSON output to reports/)
make test-only   # the original test subset used by the starter (no reports)
```

### CI (GitHub Actions)

The workflow in `.github/workflows/ci-cd.yml` runs the same steps on every push and pull request
(pytest, Playwright, Ruff, Bandit) and uploads the artifacts. There is no need to stand up a
separate CI server — after a local `git commit`, simply running `make ci` validates the same
pipeline that the workflow will run.

## Development

```bash
# If using a virtual env: source env/bin/activate
./manage.py resetdb   # to seed data
FLASK_APP=manage flask --debug run

# Go to localhost:5000 in a browser and click on Login
# Login with the credentials "user@example.com", "test"
```

## Testing

- **Backend tests** (`tests/`) use pytest and Flask's test client. `tests/test_signup_dashboard.py`
  covers the signup → dashboard flow (unit level), and `tests/test_login.py` covers login.
- **UI tests** (`tests/ui/`) use Playwright against the real running app and cover the customer
  journey: landing page → signup → dashboard, including the renamed branding.

## Deployment

MyTemplate is not tied to a specific platform for deployment, but it works well on
[Heroku](http://heroku.com) and [Dokku](http://dokku.viewdocs.io/dokku/) with minimal configuration
(see `documentation/dokku.md`).

## Stripe Webhooks Locally

- Install the [Stripe CLI](https://stripe.com/docs/stripe-cli)
- Run `stripe listen --forward-to localhost:5000/webhooks/stripe`
- Export the webhook secret (`export STRIPE_WEBHOOK_SECRET=whsec_...`)
- To replay an event: `stripe events resend evt_XYZ`

## License

This repository is a rename of [Ignite for Flask](https://github.com/sumukh/ignite), a commercial
product. Private, non-commercial use is free; commercial use requires a purchased license.
For full license details see [LICENSE.md](LICENSE.md) and the [Ignite Website](https://ignite.sumukh.me).

## Credits

Design elements from [tabler](https://github.com/tabler/tabler) & Bootstrap 4. Built off of
[Flask Foundation](https://jackstouffer.github.io/Flask-Foundation/) and the
[bootstrapy project](https://github.com/kirang89/bootstrapy).