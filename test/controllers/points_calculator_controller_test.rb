require "test_helper"

class PointsCalculatorControllerTest < ActionDispatch::IntegrationTest
  test "should get index" do
    get points_calculator_index_url
    assert_response :success
  end
end
