.PHONY: help setup deps clean test ui-test lint security ci reports agent-setup agent-resetdb agent-smoke agent-test

# Python to use. Override for non-default environments, e.g.:
#   make test PYTHON=env/bin/python
PYTHON ?= python3
PIP ?= $(PYTHON) -m pip

# Test reports + artifacts all live in one directory
REPORTS_DIR = reports

help:
	@echo "MyTemplate quality pipeline"
	@echo ""
	@echo "  make setup        create a virtualenv (env/) and install all dependencies + dev tools"
	@echo "  make deps         install runtime + dev dependencies via pip"
	@echo "  make test         run unit tests with coverage (JUnit XML + XML/HTML coverage in reports/)"
	@echo "  make ui-test      run Playwright UI tests against a live server (reports/ui/)"
	@echo "  make lint         run Ruff static analysis (machine-readable report in reports/)"
	@echo "  make security     run Bandit security scan (JSON report in reports/)"
	@echo "  make ci           run the full pipeline: lint -> security -> test -> ui-test"
	@echo "  make reports      print a summary of everything produced in reports/"
	@echo "  make clean        remove unwanted files like .pyc's and dev database"
	@echo ""
	@echo "On Windows (no make): run  powershell -ExecutionPolicy Bypass -File scripts/ci.ps1"

setup:
	$(PYTHON) -m venv env
	$(PIP) --version && $(PIP) install --upgrade pip
	$(PIP) install -r requirements.txt
	$(PIP) install ruff bandit pytest-playwright
	$(PYTHON) -m playwright install chromium

deps:
	$(PIP) install -r requirements.txt
	$(PIP) install ruff bandit pytest-playwright

test:
	@mkdir -p $(REPORTS_DIR)
	APPNAME_ENV=test $(PYTHON) -m pytest tests --ignore=tests/ui \
		--cov=appname \
		--cov-report=term-missing \
		--cov-report=xml:$(REPORTS_DIR)/coverage.xml \
		--cov-report=html:$(REPORTS_DIR)/html \
		--junitxml=$(REPORTS_DIR)/junit.xml

ui-test:
	@mkdir -p $(REPORTS_DIR)
	APPNAME_ENV=test $(PYTHON) -m pytest tests/ui --browser=chromium \
		--output=$(REPORTS_DIR)/ui \
		--junitxml=$(REPORTS_DIR)/ui-junit.xml

lint:
	@mkdir -p $(REPORTS_DIR)
	$(PYTHON) -m ruff check appname manage.py wsgi.py tests \
		--output-format=json --output-file $(REPORTS_DIR)/ruff.json
	$(PYTHON) -m ruff check appname manage.py wsgi.py tests

security:
	@mkdir -p $(REPORTS_DIR)
	$(PYTHON) -m bandit -r appname manage.py wsgi.py \
		-x "appname/static" \
		-f json -o $(REPORTS_DIR)/bandit.json -q

ci: lint security test ui-test reports

reports:
	@echo ""
	@echo "===== Build artifacts in $(REPORTS_DIR)/ ====="
	@ls -la $(REPORTS_DIR)
	@echo ""
	@echo "Unit tests:        $(REPORTS_DIR)/junit.xml         (JUnit XML)"
	@echo "Coverage (XML):    $(REPORTS_DIR)/coverage.xml"
	@echo "Coverage (HTML):   $(REPORTS_DIR)/html/             (open index.html)"
	@echo "UI tests:          $(REPORTS_DIR)/ui-junit.xml + $(REPORTS_DIR)/ui/"
	@echo "Static analysis:   $(REPORTS_DIR)/ruff.json          (JSON)"
	@echo "Security scan:     $(REPORTS_DIR)/bandit.json        (JSON)"
	@echo ""
	@echo "Full coverage numbers: see $(REPORTS_DIR)/coverage.xml / reports/html/index.html"

clean:
	find . -name "__pycache__" -type d -prune -exec rm -rf {} +
	-rm -f database.db reports/coverage.xml
	-rm -rf $(REPORTS_DIR) test-results

# --- Legacy agent targets (kept for compatibility with AGENTS.md) ---

agent-setup:
	$(PYTHON) -m venv env
	env/bin/python -m pip install --upgrade pip
	env/bin/python -m pip install -r requirements.txt
	env/bin/python -m pip install ruff bandit pytest-playwright

agent-resetdb:
	@if [ ! -x "env/bin/python" ]; then echo "Run 'make agent-setup' first."; exit 1; fi
	APPNAME_ENV=dev env/bin/python manage.py resetdb

agent-smoke:
	@if [ ! -x "env/bin/python" ]; then echo "Run 'make agent-setup' first."; exit 1; fi
	APPNAME_ENV=test env/bin/python -m pytest -q tests/test_urls.py tests/test_login.py

agent-test:
	@if [ ! -x "env/bin/python" ]; then echo "Run 'make agent-setup' first."; exit 1; fi
	APPNAME_ENV=test env/bin/python -m pytest -q tests/test_urls.py tests/test_login.py tests/test_branding.py