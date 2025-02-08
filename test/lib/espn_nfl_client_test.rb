require "test_helper"
require "minitest/mock"
require "mocks/espn_nfl_client_http_mock"

class EspnNflClientTest < ActiveSupport::TestCase
  def setup
    @group_one = groups(:one)
    @team_one = teams(:one)
    @position_wr = positions(:wide_receiver)
    @client = EspnNfl::Client.new
    @updater = EspnNfl::Updater.new
    @espn_mock_responses = EspnNflClientHttpMock.load_responses
  end

  test "should upsert groups" do
    Net::HTTP.stub :get_response, EspnNflClientHttpMock.method(:get_response_ok) do
      assert_difference("Group.count", +2) do
        result = @updater.fetch_and_upsert_groups
        assert_not_nil result
      end

      parent_id = nil

      Group.where(espn_id: 0).first.tap do |group|
        assert_not_nil group
        assert_equal group.name, "American Football Conference"
        assert_equal group.abbreviation, "AFC"
        assert_equal group.is_conference, true
        parent_id = group.id
      end

      Group.where(espn_id: 11).first.tap do |group|
        assert_not_nil group
        assert_equal group.name, "AFC North"
        assert_equal group.abbreviation, "NORTH"
        assert_equal group.is_conference, false
        assert_equal group.parent_id, parent_id
      end
    end
  end

  test "should fail to upsert groups" do
    Net::HTTP.stub :get_response, EspnNflClientHttpMock.method(:get_response_not_found) do
      assert_raises StandardError do
        @updater.fetch_and_upsert_groups
      end
    end
  end

  test "should upsert teams" do
    Net::HTTP.stub :get_response, EspnNflClientHttpMock.method(:get_response_ok) do
      assert_difference("Team.count", +1) do
        result = @updater.fetch_and_upsert_groups_teams([ @group_one.espn_id ])
        assert_not_nil result
      end

      Team.where(espn_id: 1).first.tap do |team|
        assert_not_nil team
        assert_equal team.name, "Bengals"
        assert_equal team.abbreviation, "CIN"
        assert_equal team.is_active, true
        assert_equal team.group_id, @group_one.id
      end
    end
  end

  test "should upsert positions" do
    Net::HTTP.stub :get_response, EspnNflClientHttpMock.method(:get_response_ok) do
      response = @updater.fetch_and_upsert_positions
      assert_not_nil response, "Expected fetch_positions to return a response"
    end
  end

  test "should upsert athletes" do
    athlete1_ref = @espn_mock_responses["teams/int/athletes?page=1"]["items"][0]["$ref"]
    athlete1_url = @client.ref_to_url(athlete1_ref).to_s
    Typhoeus.stub(athlete1_url) do
      Typhoeus::Response.new(
        body: @espn_mock_responses["athletes/1"].to_json,
      )
    end

    athlete2_ref = @espn_mock_responses["teams/int/athletes?page=2"]["items"][0]["$ref"]
    athlete2_url = @client.ref_to_url(athlete2_ref).to_s
    Typhoeus.stub(athlete2_url) do
      Typhoeus::Response.new(
        body: @espn_mock_responses["athletes/2"].to_json,
      )
    end

    Net::HTTP.stub :get_response, EspnNflClientHttpMock.method(:get_response_ok) do
      assert_difference("Athlete.count", +2) do
        athletes_created = @updater.fetch_and_upsert_teams_athletes([ @team_one.espn_id ])
        assert_not_nil athletes_created
      end

      Athlete.where(espn_id: 1).first.tap do |athlete|
        assert_not_nil athlete
        assert_equal athlete.first_name, "Micah"
        assert_equal athlete.last_name, "Abraham"
        assert_equal athlete.position_id, @position_wr.id
        assert_equal athlete.team_id, @team_one.id
      end

      Athlete.where(espn_id: 2).first.tap do |athlete|
        assert_not_nil athlete
        assert_equal athlete.first_name, "Cal"
        assert_equal athlete.last_name, "Adomitis"
        assert_equal athlete.position_id, @position_wr.id
        assert_equal athlete.team_id, @team_one.id
      end
    end
  end

  test "should upsert all" do
    athlete1_ref = @espn_mock_responses["teams/int/athletes?page=1"]["items"][0]["$ref"]
    athlete1_url = @client.ref_to_url(athlete1_ref).to_s
    Typhoeus.stub(athlete1_url) do
      Typhoeus::Response.new(
        body: @espn_mock_responses["athletes/1"].to_json,
      )
    end

    athlete2_ref = @espn_mock_responses["teams/int/athletes?page=2"]["items"][0]["$ref"]
    athlete2_url = @client.ref_to_url(athlete2_ref).to_s
    Typhoeus.stub(athlete2_url) do
      Typhoeus::Response.new(
        body: @espn_mock_responses["athletes/2"].to_json,
      )
    end

    Net::HTTP.stub :get_response, EspnNflClientHttpMock.method(:get_response_ok) do
      assert_difference("Group.count", +2) do
        assert_difference("Team.count", +1) do
          assert_difference("Athlete.count", +2) do
            @updater.fetch_and_upsert_all
          end
        end
      end
    end
  end
end
