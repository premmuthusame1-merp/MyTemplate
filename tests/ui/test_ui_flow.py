"""End-to-end UI tests (Playwright, pytest-playwright).

These cover the real customer journey against a running server:
landing page -> signup -> dashboard, plus login with a seeded account.
They are small but meaningful and verify the renamed branding end to end.
"""
import re
import time

import pytest
from playwright.sync_api import expect

pytestmark = pytest.mark.ui


def test_landing_page_shows_mytemplate_branding(page, server_url):
    page.goto(server_url + "/")

    expect(page).to_have_title(re.compile("MyTemplate"))
    header = page.locator("div.nav-header")
    expect(header).to_contain_text("MyTemplate")

    footer = page.locator("footer.footer")
    expect(footer).to_contain_text("Powered by")
    expect(footer).to_contain_text("MyTemplate")


def test_signup_flow_lands_on_dashboard(page, server_url):
    email = f"ui-user-{int(time.time())}@example.com"

    page.goto(server_url + "/signup")
    expect(page).to_have_title(re.compile("MyTemplate"))

    page.get_by_label("Email").fill(email)
    page.get_by_label("Password", exact=True).fill("supersafepassword")
    page.get_by_label("Confirm Password", exact=True).fill("supersafepassword")
    page.get_by_role("button", name="Sign Up").click()

    expect(page).to_have_url(re.compile(r"/dashboard/"))
    expect(page.locator("body")).to_contain_text("Welcome to MyTemplate.")
    expect(page.locator("body")).to_contain_text("Dashboard")


def test_login_with_seeded_account(page, server_url):
    page.goto(server_url + "/login")

    page.get_by_label("Email").fill("user@example.com")
    page.get_by_label("Password").fill("test")
    page.get_by_role("button", name="Login").click()

    expect(page).to_have_url(re.compile(r"/dashboard/"))
    expect(page.locator("body")).to_contain_text("Logged in successfully.")


def test_login_rejects_wrong_password(page, server_url):
    page.goto(server_url + "/login")

    page.get_by_label("Email").fill("user@example.com")
    page.get_by_label("Password").fill("wrong-password")
    page.get_by_role("button", name="Login").click()

    expect(page.locator("body")).to_contain_text("Invalid email or password")