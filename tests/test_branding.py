import pytest

create_user = True

# These tests validate the rename from the customer/QA perspective:
# the branding that users actually see in the UI must say "MyTemplate".


@pytest.mark.usefixtures("testapp")
class TestBranding:
    def test_landing_page_uses_new_brand(self, testapp):
        response = testapp.get("/")
        assert response.status_code == 200
        body = response.get_data(as_text=True)

        assert "<title>MyTemplate</title>" in body
        assert "MyTemplate is a starting point for Flask web applications" in body
        assert "Powered by <a href=\"https://github.com/sumukh/ignite\">MyTemplate</a> for Flask" in body

    def test_login_page_uses_new_brand(self, testapp):
        response = testapp.get("/login")
        assert response.status_code == 200
        body = response.get_data(as_text=True)

        assert "<title>MyTemplate Login Example</title>" in body
        assert "MyTemplate" in body

    def test_signup_page_uses_new_brand(self, testapp):
        response = testapp.get("/signup")
        assert response.status_code == 200
        body = response.get_data(as_text=True)

        assert "Sign up for MyTemplate" in body

    def test_signup_flow_welcomes_user_with_new_brand(self, testapp):
        response = testapp.post(
            "/signup",
            data={
                "email": "brand-check@example.com",
                "password": "supersafepassword",
                "confirm": "supersafepassword",
            },
            follow_redirects=True,
        )
        assert response.status_code == 200
        assert "Welcome to MyTemplate." in response.get_data(as_text=True)