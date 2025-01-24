require "test_helper"

class SessionsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @session = sessions(:session_one)
    @user = users(:user_one)
  end

  test "should get new" do
    get new_session_url
    assert_response :success
  end

  test "should create session" do
    assert_difference("Session.count") do
      post session_url, params: {
        email_address: @user.email_address,
        password: "password"
      }
    end

    assert_redirected_to root_url
  end

  test "should destroy session" do
    sign_in_as @user

    assert_difference("Session.count", -1) do
      delete session_url
    end

    assert_redirected_to new_session_url
  end

  test "should not create session" do
    assert_no_difference("Session.count") do
      post session_url, params: {
        email_address: @user.email_address,
        password: "wrong_password"
      }
    end

    assert_redirected_to new_session_url
  end

  test "should not create session with wrong password" do
    post session_url, params: { email_address: @user.email_address, password: "wrong_password" }

    assert_redirected_to new_session_url
    assert_equal "Try another email address or password.", flash[:alert]
  end

  test "should not create session with wrong email" do
    post session_url, params: { email_address: "wrong_email@example.com", password: TestEnv::Constants::DEFAULT_PASSWORD }

    assert_redirected_to new_session_url
    assert_equal "Try another email address or password.", flash[:alert]
  end
end
