require "application_system_test_case"

class UsersTest < ApplicationSystemTestCase
  setup do
    @user = users(:user_one)
  end

  test "should create user" do
    visit new_user_url
    fill_in "user_username", with: "dontusetestasusernamebug"
    fill_in "user_email_address", with: "test@example.com"
    fill_in "user_password", with: TestEnv::Constants::DEFAULT_PASSWORD
    fill_in "user_password_confirmation", with: TestEnv::Constants::DEFAULT_PASSWORD

    click_on "Sign Up"

    assert_text "User was successfully created"
  end

  # test "should update User" do
  #   visit user_url(@user)
  #   click_on "Edit this user", match: :first

  #   click_on "Update User"

  #   assert_text "User was successfully updated"
  #   click_on "Back"
  # end
end
