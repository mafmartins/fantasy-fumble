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

  test "should not create user with different password confirmation" do
    visit new_user_url
    fill_in "user_username", with: "dontusetestasusernamebug"
    fill_in "user_email_address", with: "test@example.com"
    fill_in "user_password", with: TestEnv::Constants::DEFAULT_PASSWORD
    fill_in "user_password_confirmation", with: "different_password"

    click_on "Sign Up"

    assert_text "The password must be the same."
  end

  test "should not create duplicate user" do
    visit new_user_url
    fill_in "user_username", with: @user.username
    fill_in "user_email_address", with: @user.email_address
    fill_in "user_password", with: TestEnv::Constants::DEFAULT_PASSWORD
    fill_in "user_password_confirmation", with: TestEnv::Constants::DEFAULT_PASSWORD

    click_on "Sign Up"

    assert_text "has already been taken"
  end

  test "should not create user with invalid email address" do
    visit new_user_url
    fill_in "user_username", with: "dontusetestasusernamebug"
    fill_in "user_email_address", with: "testexample.com"
    fill_in "user_password", with: TestEnv::Constants::DEFAULT_PASSWORD
    fill_in "user_password_confirmation", with: TestEnv::Constants::DEFAULT_PASSWORD

    click_on "Sign Up"

    assert_text "Please provide a valid email address."
  end
end
