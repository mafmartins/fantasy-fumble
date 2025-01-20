require "test_helper"

class ApplicationSystemTestCase < ActionDispatch::SystemTestCase
  driven_by :selenium, using: :headless_chrome, screen_size: [ 1400, 1400 ], options: {
    browser: :remote,
    url: "http://#{ENV.fetch("SELENIUM_HOST", "localhost")}:4444"
  }
end
