require "test_helper"

class UsersControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:user_one)
  end

  test "should get new" do
    get new_user_url
    assert_response :success
  end

  test "should create user" do
    assert_difference("User.count") do
      post users_url, params: { user: { username: "Test", email_address: "test@example.com", password: TestEnv::Constants::DEFAULT_PASSWORD, password_confirmation: TestEnv::Constants::DEFAULT_PASSWORD } }
    end

    assert_redirected_to new_session_url
  end

  test "should not create duplicate user" do
    post users_url, params: { user: { username: @user.username, email_address: @user.email_address, password: TestEnv::Constants::DEFAULT_PASSWORD, password_confirmation: TestEnv::Constants::DEFAULT_PASSWORD } }

    assert_no_difference("User.count") do
      post users_url, params: { user: { username: @user.username, email_address: @user.email_address, password: TestEnv::Constants::DEFAULT_PASSWORD, password_confirmation: TestEnv::Constants::DEFAULT_PASSWORD } }
    end

    assert_redirected_to new_user_url
    assert_equal "has already been taken", flash[:alert][:username].first
  end

  test "should not create user with different password confirmation" do
    assert_no_difference("User.count") do
      post users_url, params: { user: { username: "Test", email_address: "test@example.com", password: TestEnv::Constants::DEFAULT_PASSWORD, password_confirmation: "different_password" } }
    end

    assert_redirected_to new_user_url
    assert_equal "doesn't match Password", flash[:alert][:password_confirmation].first
  end
end
