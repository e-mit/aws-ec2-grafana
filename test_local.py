import os
import time

import pytest
from selenium import webdriver
from selenium.webdriver.common.by import By
from selenium.webdriver.support.wait import WebDriverWait
from selenium.webdriver.support import expected_conditions as EC
import chromedriver_autoinstaller


PUBLIC_PORT = os.environ['PUBLIC_PORT']
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


def test_subdomain(driver) -> None:
    driver.get(f"http://grafana.localhost:{PUBLIC_PORT}")
    check_grafana(driver)


def test_redirect(driver) -> None:
    driver.get(f"http://localhost:{PUBLIC_PORT}/grafana-public")
    check_grafana(driver)
