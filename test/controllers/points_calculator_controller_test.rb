require "test_helper"
require "mocks/espn_nfl_client_http_mock"

class PointsCalculatorControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:user_one)
    @athletes = [ athletes(:one), athletes(:two) ]
    @espn_mock_responses = EspnNflClientHttpMock.load_responses
    @client = EspnNfl::Client.new(2024, test: true)

    athlete1_eventlog_path = "/seasons/2024/athletes/#{athletes[0].espn_id}/eventlog"
    athlete1_eventlog_url = @client.path_to_url(athlete1_eventlog_path).to_s
    Typhoeus.stub(athlete1_eventlog_url) do
      Typhoeus::Response.new(
        body: @espn_mock_responses["athletes/1/eventlog"].to_json,
        code: 200,
      )
    end

    athlete2_eventlog_path = "/seasons/2024/athletes/#{athletes[1].espn_id}/eventlog"
    athlete2_eventlog_url = @client.path_to_url(athlete2_eventlog_path).to_s
    Typhoeus.stub(athlete2_eventlog_url) do
      Typhoeus::Response.new(
        body: @espn_mock_responses["athletes/2/eventlog"].to_json,
        code: 200,
      )
    end

    athlete1_event1_stats_path = "/events/1/competitions/1/competitors/99/roster/#{athletes[0].espn_id}/statistics/0"
    athlete1_event1_stats_url = @client.path_to_url(athlete1_event1_stats_path).to_s
    Typhoeus.stub(athlete1_event1_stats_url) do
      Typhoeus::Response.new(
        body: @espn_mock_responses["events/1/competitions/1/competitors/1/roster/1/statistics/0"].to_json,
        code: 200,
      )
    end

    athlete2_event1_stats_path = "/events/1/competitions/1/competitors/99/roster/#{athletes[1].espn_id}/statistics/0"
    athlete2_event1_stats_url = @client.ref_to_url(athlete2_event1_stats_path).to_s
    Typhoeus.stub(athlete2_event1_stats_url) do
      Typhoeus::Response.new(
        body: @espn_mock_responses["events/1/competitions/1/competitors/1/roster/2/statistics/0"].to_json,
        code: 200,
      )
    end
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
      season: "2024",
      week: "1"
    }
    assert_response :success
  end
end
