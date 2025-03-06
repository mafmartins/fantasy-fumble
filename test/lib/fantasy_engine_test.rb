require "test_helper"
require "minitest/mock"
require "mocks/espn_nfl_client_http_mock"

class FantasyEngineTest < ActiveSupport::TestCase
  setup do
    @athletes = [ athletes(:one), athletes(:two) ]
    @espn_mock_responses = EspnNflClientHttpMock.load_responses
    @client = EspnNfl::Client.new(2024, test: true)
    @engine = Fantasy::Engine.new(2024, 1)

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

  def test_calculate_points
    result = @engine.calculate_athletes_points(@athletes)

    assert_not_nil result
    assert_equal 2, result.length
    assert_equal(
      {
        980190962 =>
        {
          extra_points: 4.0,
          extra_points_missed: -0.0,
          field_goals_made1_39: 0.0,
          field_goals_made40_49: 8.0,
          field_goals_made50plus: 0.0,
          field_goals_missed: -2.0 },
        298486374 =>
        {
          passing_yards: 0.0,
          passing_touchdowns: 0.0,
          interceptions: -0.0,
          rushing_yards: 0.4,
          rushing_touchdowns: 0.0,
          receiving_yards: 7.8,
          receiving_touchdowns: 12.0,
          fumbles_lost: -0.0,
          fumbles_touchdowns: 0.0
        }
      },
      result
    )
  end
end
