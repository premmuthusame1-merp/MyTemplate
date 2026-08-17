import os
import socket
import subprocess
import sys
import time
import urllib.error
import urllib.request

import pytest

REPO_ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))


def _free_port():
    s = socket.socket()
    s.bind(("127.0.0.1", 0))
    port = s.getsockname()[1]
    s.close()
    return port


@pytest.fixture(scope="session")
def live_server():
    """Start the real MyTemplate dev server once, against a seeded sqlite DB,
    and expose its base URL to the UI tests. Mirrors a local `make server` run.
    """
    port = _free_port()
    base_url = f"http://127.0.0.1:{port}"
    env = dict(os.environ, APPNAME_ENV="dev")

    subprocess.check_call(
        [sys.executable, "manage.py", "resetdb"],
        cwd=REPO_ROOT,
        env=env,
        stdout=subprocess.DEVNULL,
    )

    server_cmd = (
        "from appname import create_app;"
        f"create_app('appname.settings.DevConfig').run(host='127.0.0.1', port={port},"
        "debug=False, use_reloader=False, threaded=True)"
    )
    proc = subprocess.Popen(
        [sys.executable, "-u", "-c", server_cmd],
        cwd=REPO_ROOT,
        env=env,
        stdout=subprocess.DEVNULL,
        stderr=subprocess.DEVNULL,
    )

    try:
        _wait_until_ready(base_url)
        yield base_url
    finally:
        if sys.platform == "win32":
            subprocess.run(
                ["taskkill", "/F", "/T", "/PID", str(proc.pid)],
                stdout=subprocess.DEVNULL,
                stderr=subprocess.DEVNULL,
            )
        else:
            proc.terminate()
            proc.wait(timeout=10)


def _wait_until_ready(url, timeout=60):
    deadline = time.time() + timeout
    while time.time() < deadline:
        try:
            urllib.request.urlopen(url, timeout=2)
            return
        except (urllib.error.URLError, ConnectionError, OSError):
            time.sleep(0.5)
    raise RuntimeError(f"Dev server at {url} did not become ready in {timeout}s")


@pytest.fixture
def server_url(live_server):
    return live_server


@pytest.fixture(autouse=True)
def _generous_timeouts(page):
    # Asset-heavy pages (remote theme CSS, font CDNs) can be slow on first
    # load; give navigation and assertions more room than Playwright's 30s.
    page.set_default_timeout(60_000)
    yield