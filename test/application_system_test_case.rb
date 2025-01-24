require "test_helper"

class ApplicationSystemTestCase < ActionDispatch::SystemTestCase
  # Reference: https://stackoverflow.com/questions/53902507/unknown-error-session-deleted-because-of-page-crash-from-unknown-error-cannot
  driven_by :selenium, using: :headless_chrome, screen_size: [ 1400, 1400 ], options: { browser: :remote, url: "http://#{ENV.fetch("SELENIUM_HOST", "localhost")}:4444/wd/hub" }  do |driver_options|
    driver_options.add_argument("--disable-dev-shm-usage")
    driver_options.add_argument("--no-sandbox")
    driver_options.add_argument("--disable-gpu")
  end
end
