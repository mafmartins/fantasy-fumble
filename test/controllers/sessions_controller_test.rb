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
    post session_url, params: {
      email_address: @user.email_address,
      password: "password"
    }

    assert_redirected_to root_url

    assert_difference("Session.count", -1) do
      delete session_url
    end

    assert_redirected_to new_session_url
  end
end
