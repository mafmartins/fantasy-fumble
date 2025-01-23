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

  test "should show user" do
    sign_in_as @user

    get user_url(@user)
    assert_response :success
  end

  test "should get edit" do
    sign_in_as @user

    get edit_user_url(@user)
    assert_response :success
  end

  test "should update user" do
    sign_in_as @user

    patch user_url(@user), params: { user: { username: "Test_changed" } }
    assert_redirected_to user_url(@user)
  end
end
