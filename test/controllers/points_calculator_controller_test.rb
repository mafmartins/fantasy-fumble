require "test_helper"
require "mocks/espn_nfl_client_http_mock"

class PointsCalculatorControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:user_one)
    @athletes = [ athletes(:one), athletes(:two) ]
    @espn_mock_responses = EspnNflClientHttpMock.load_responses
    @client = EspnNfl::Client.new(2024, test: true)
  end
  test "should get index" do
    sign_in_as @user

    get points_calculator_index_url
    assert_response :success
  end

  test "should calculate points" do
    athlete1_eventlog_ref = @espn_mock_responses["athletes/1/eventlog"]["$ref"]
    athlete1_eventlog_url = @client.ref_to_url(athlete1_eventlog_ref).to_s
    Typhoeus.stub(athlete1_eventlog_url) do
      Typhoeus::Response.new(
        body: @espn_mock_responses["athletes/1/eventlog"].to_json,
        code: 200,
      )
    end

    athlete2_eventlog_ref = @espn_mock_responses["athletes/2/eventlog"]["$ref"]
    athlete2_eventlog_url = @client.ref_to_url(athlete2_eventlog_ref).to_s
    Typhoeus.stub(athlete2_eventlog_url) do
      Typhoeus::Response.new(
        body: @espn_mock_responses["athletes/2/eventlog"].to_json,
        code: 200,
      )
    end

    athlete1_event1_stats_ref = @espn_mock_responses["athletes/1/eventlog"]["events"]["items"][0]["statistics"]["$ref"]
    athlete1_event1_stats_url = @client.ref_to_url(athlete1_event1_stats_ref).to_s
    Typhoeus.stub(athlete1_event1_stats_url) do
      Typhoeus::Response.new(
        body: @espn_mock_responses["events/1/competitions/1/competitors/1/roster/1/statistics/0"].to_json,
        code: 200,
      )
    end

    athlete2_event1_stats_ref = @espn_mock_responses["athletes/2/eventlog"]["events"]["items"][0]["statistics"]["$ref"]
    athlete2_event1_stats_url = @client.ref_to_url(athlete2_event1_stats_ref).to_s
    Typhoeus.stub(athlete2_event1_stats_url) do
      Typhoeus::Response.new(
        body: @espn_mock_responses["events/1/competitions/1/competitors/1/roster/2/statistics/0"].to_json,
        code: 200,
      )
    end

    sign_in_as @user

    post points_calculator_calculate_url, params: {
      athletes: [ @athletes[0].id, @athletes[1].id ],
      season: "2024",
      week: "1"
    }
    assert_response :success
  end
end
