require "test_helper"

class PointsCalculatorControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:user_one)
    @athletes = [ athletes(:one), athletes(:two) ]
  end
  test "should get index" do
    sign_in_as @user

    get points_calculator_index_url
    assert_response :success
  end

  test "should calculate points" do
    sign_in_as @user

    post points_calculator_calculate_url, params: {
      athletes: [ @athletes[0].id, @athletes[1].id ],
      season: "2025",
      week: "1"
    }
    assert_response :success
  end
end
