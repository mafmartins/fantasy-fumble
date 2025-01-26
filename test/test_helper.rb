ENV["RAILS_ENV"] ||= "test"
require "simplecov"
require_relative "../config/environment"
require "rails/test_help"

SimpleCov.start

Capybara.server_host = "0.0.0.0"
Capybara.app_host = "http://#{IPSocket.getaddress(Socket.gethostname)}:#{Capybara.server_port}"

module ActiveSupport
  class TestCase
    # Run tests in parallel with specified workers
    parallelize(workers: :number_of_processors)

    # Setup all fixtures in test/fixtures/*.yml for all tests in alphabetical order.
    fixtures :all

    # Add more helper methods to be used by all tests here...
  end
end

module SignInHelperIntegrationTests
  def sign_in_as(user)
    post session_url, params: { email_address: user.email_address, password: TestEnv::Constants::DEFAULT_PASSWORD }

    assert session.values.count == 1
  end
end

class ActionDispatch::IntegrationTest
  include SignInHelperIntegrationTests
end

module SignInHelperSystemTests
  def sign_in_as(user)
    visit new_session_url

    fill_in "email_address", with: user.email_address
    fill_in "password", with: TestEnv::Constants::DEFAULT_PASSWORD

    click_on "commit"

    assert_text "About Fantasy Fumble"
  end
end

class ActionDispatch::SystemTestCase
  include SignInHelperSystemTests
end
