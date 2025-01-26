require "test_helper"

class PointsCalculatorControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:user_one)
  end
  test "should get index" do
    sign_in_as @user

    get points_calculator_index_url
    assert_response :success
  end
end
