"""Simple tests running only the Grafana container locally (not with nginx).

This uses nginx without TLS, and can use either a
PostgreSQL or SQLite database.
"""
import time

import pytest
from selenium import webdriver
import chromedriver_autoinstaller


PUBLIC_PORT = 3000
TIMEOUT_S = 30
chromedriver_autoinstaller.install()


@pytest.fixture
def driver():
    time.sleep(4)  # Delay to prevent Nginx 503 rate limiting
    options = webdriver.ChromeOptions()
    options.add_argument('--headless')
    driver = webdriver.Chrome(options=options)
    driver.set_page_load_timeout(TIMEOUT_S)
    driver.set_script_timeout(TIMEOUT_S)
    driver.implicitly_wait(TIMEOUT_S)
    yield driver
    driver.quit()


def check_grafana(drv) -> None:
    assert "Grafana" in drv.title
    assert "Grafana" in drv.page_source


def test_login(driver) -> None:
    driver.get(f"http://localhost:{PUBLIC_PORT}/login")
    check_grafana(driver)


def test_index(driver) -> None:
    driver.get(f"http://localhost:{PUBLIC_PORT}/")
    check_grafana(driver)
