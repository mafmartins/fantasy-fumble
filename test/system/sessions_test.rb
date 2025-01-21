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

    assert_text "About Fantasy Fumble"
  end

  # test "should update Session" do
  #   visit session_url(@session)
  #   click_on "Edit this session", match: :first

  #   click_on "Update Session"

  #   assert_text "Session was successfully updated"
  #   click_on "Back"
  # end

  # test "should destroy Session" do
  #   visit session_url(@session)
  #   click_on "Destroy this session", match: :first

  #   assert_text "Session was successfully destroyed"
  # end
end
