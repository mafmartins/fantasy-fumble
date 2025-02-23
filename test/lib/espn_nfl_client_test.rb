require "test_helper"
require "minitest/mock"
require "mocks/espn_nfl_client_http_mock"

class EspnNflUpdaterTest < ActiveSupport::TestCase
  def setup
    @group_one = groups(:one)
    @team_one = teams(:one)
    @position_wr = positions(:wide_receiver)
    @client = EspnNfl::Client.new(2024, test: true)
    @espn_mock_responses = EspnNflClientHttpMock.load_responses
  end

  test "should fetch group" do
    parent_group_ref = @espn_mock_responses["groups/parent_int"]["$ref"]
    parent_group_url = @client.ref_to_url(parent_group_ref).to_s
    Typhoeus.stub(parent_group_url) do
      Typhoeus::Response.new(
        body: @espn_mock_responses["groups/parent_int"].to_json,
        code: 200,
      )
    end

    @client.fetch_groups([ 0 ]).tap do |groups|
      assert_not_nil groups
      assert_equal 1, groups.length, 1

      assert_equal(
        {
          espn_id: 0,
          name: "American Football Conference",
          abbreviation: "AFC",
          is_conference: true,
          is_active: true,
          parent_espn_id: nil
        },
        groups[0]
      )
    end
  end

  test "should fetch group with parent" do
    # Create parent group
    Group.create(
      espn_id: 0,
      name: "American Football Conference",
      abbreviation: "AFC",
      is_conference: true,
      is_active: true,
    )

    child_group_ref = @espn_mock_responses["groups/child_int"]["$ref"]
    child_group_url = @client.ref_to_url(child_group_ref).to_s
    Typhoeus.stub(child_group_url) do
      Typhoeus::Response.new(
        body: @espn_mock_responses["groups/child_int"].to_json,
        code: 200,
      )
    end

    @client.fetch_groups([ 11 ]).tap do |groups|
      assert_not_nil groups
      assert_equal 1, groups.length

      assert_equal(
        {
          espn_id: 11,
          name: "AFC North",
          abbreviation: "NORTH",
          is_conference: false,
          is_active: true,
          parent_espn_id: 0
        },
        groups[0]
      )
    end
  end

  test "should fetch groups without parent and with parent" do
    parent_group_ref = @espn_mock_responses["groups/parent_int"]["$ref"]
    parent_group_url = @client.ref_to_url(parent_group_ref).to_s
    Typhoeus.stub(parent_group_url) do
      Typhoeus::Response.new(
        body: @espn_mock_responses["groups/parent_int"].to_json,
        code: 200,
      )
    end

    child_group_ref = @espn_mock_responses["groups/child_int"]["$ref"]
    child_group_url = @client.ref_to_url(child_group_ref).to_s
    Typhoeus.stub(child_group_url) do
      Typhoeus::Response.new(
        body: @espn_mock_responses["groups/child_int"].to_json,
        code: 200,
      )
    end

    # 0 is parent group, 11 is child group
    # as defined in the mock responses
    @client.fetch_groups([ 0, 11 ]).tap do |groups|
      assert_not_nil groups
      assert_equal 2, groups.length

      assert_equal(
        {
          espn_id: 0,
          name: "American Football Conference",
          abbreviation: "AFC",
          is_conference: true,
          is_active: true,
          parent_espn_id: nil
        },
        groups[0]
      )

      assert_equal(
        {
          espn_id: 11,
          name: "AFC North",
          abbreviation: "NORTH",
          is_conference: false,
          is_active: true,
          parent_espn_id: 0
        },
        groups[1]
      )
    end
  end

  test "should fetch positions" do
    position_ref = @espn_mock_responses["positions/1"]["$ref"]
    position_url = @client.ref_to_url(position_ref).to_s
    Typhoeus.stub(position_url) do
      Typhoeus::Response.new(
        body: @espn_mock_responses["positions/1"].to_json,
        code: 200,
      )
    end

    @client.fetch_positions([ 1 ]).tap do |positions|
      assert_not_nil positions
      assert_equal 1, positions.length

      assert_equal(
        {
          espn_id: 1,
          name: "Wide Receiver",
          abbreviation: "WR",
          is_active: true,
          parent_espn_id: 70
        },
        positions[0]
      )
    end
  end

  test "should fetch teams" do
    team_ref = @espn_mock_responses["teams/int"]["$ref"]
    team_url = @client.ref_to_url(team_ref).to_s
    Typhoeus.stub(team_url) do
      Typhoeus::Response.new(
        body: @espn_mock_responses["teams/int"].to_json,
        code: 200,
      )
    end

    @client.fetch_teams([ 1 ]).tap do |teams|
      assert_not_nil teams
      assert_equal 1, teams.length

      assert_equal(
        {
          espn_id: 1,
          slug: "cincinnati-bengals",
          abbreviation: "CIN",
          display_name: "Cincinnati Bengals",
          short_display_name: "Bengals",
          name: "Bengals",
          nickname: "Bengals",
          location: "Cincinnati",
          color: "fb4f14",
          alternate_color: "000000",
          logo: "https://a.espncdn.com/i/teamlogos/nfl/500/cin.png",
          is_active: true,
          group_espn_id: 11
        },
        teams[0]
      )
    end
  end

  test "should fetch athletes" do
    athlete_ref = @espn_mock_responses["athletes/1"]["$ref"]
    athlete_url = @client.ref_to_url(athlete_ref).to_s
    Typhoeus.stub(athlete_url) do
      Typhoeus::Response.new(
        body: @espn_mock_responses["athletes/1"].to_json,
        code: 200,
      )
    end

    @client.fetch_athletes([ 1 ]).tap do |athletes|
      assert_not_nil athletes
      assert_equal 1, athletes.length

      assert_equal(
        {
          espn_id: 1,
          first_name: "Micah",
          last_name: "Abraham",
          full_name: "Micah Abraham",
          display_name: "Micah Abraham",
          short_name: "M. Abraham",
          weight: 185.0,
          height: 71.0,
          age: 24,
          date_of_birth: "2000-12-11T08:00Z",
          experience_years: 0,
          jersey: 40,
          headshot: "https://a.espncdn.com/i/headshots/nfl/players/full/1.png",
          position_espn_id: 1,
          team_espn_id: 4,
          is_active: true
        },
        athletes[0]
      )
    end
  end

  test "should fetch athlete eventlog" do
    Net::HTTP.stub :get_response, EspnNflClientHttpMock.method(:get_response_ok) do
      @client.fetch_athlete_eventlog(1).tap do |eventlog|
        assert_not_nil eventlog
        assert_equal(
          [
            {
              event_ref: "http://sports.core.api.espn.com/v2/sports/football/leagues/nfl/events/1?lang=en&region=us",
              statistics_ref: "http://sports.core.api.espn.com/v2/sports/football/leagues/nfl/events/1/competitions/1/competitors/1/roster/1/statistics/0?lang=en&region=us",
              team_espn_id: 1,
              played: true,
              week: 1
            },
            {
              event_ref: "http://sports.core.api.espn.com/v2/sports/football/leagues/nfl/events/2?lang=en&region=us",
              statistics_ref: nil,
              team_espn_id: 1,
              played: false,
              week: 2
            }
          ],
          eventlog
        )
      end
    end
  end
end
