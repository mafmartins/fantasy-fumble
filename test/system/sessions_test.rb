require "application_system_test_case"

class SessionsTest < ApplicationSystemTestCase
  setup do
    @session = sessions(:session_one)
    @user = users(:user_one)
  end

  test "visiting the index" do
    visit new_session_url
    assert_selector "input", class: "btn"
  end

  test "should create session" do
    visit new_session_url

    fill_in "email_address", with: @user.email_address
    fill_in "password", with: TestEnv::Constants::DEFAULT_PASSWORD

    click_on "commit"

    # Redirected to root_url
    assert_text "About Fantasy Fumble"
  end

  test "should destroy Session" do
    sign_in_as @user

    visit root_url(@session)
    click_on "Sign Out", match: :first

    assert_text "Sign In"
  end
end
