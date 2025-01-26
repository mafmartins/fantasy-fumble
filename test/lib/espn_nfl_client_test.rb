require "test_helper"
require "minitest/mock"
require "mocks/espn_nfl_client_http_mock"

class EspnNflClientTest < ActiveSupport::TestCase
  def setup
    @group_one = groups(:one)
    @client = EspnNfl::Client.new
    @espn_mock_responses = EspnNflClientHttpMock.load_responses
  end

  test "should fetch all groups and save them" do
    Net::HTTP.stub :get_response, EspnNflClientHttpMock.method(:get_response_ok) do
      assert_difference("Group.count", +2) do
        groups_created = @client.fetch_groups
        assert_not_nil groups_created
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

  test "should fail to fetch groups" do
    Net::HTTP.stub :get_response, EspnNflClientHttpMock.method(:get_response_not_found) do
      assert_raises StandardError do
        @client.fetch_groups
      end
    end
  end

  test "should fetch teams" do
    Net::HTTP.stub :get_response, EspnNflClientHttpMock.method(:get_response_ok) do
      assert_difference("Team.count", +1) do
       teams_created = @client.fetch_groups_teams([ 99 ])
       assert_not_nil teams_created
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

  # test "should fetch athletes" do
  #   response = @client.fetch_athletes
  #   assert_not_nil response, "Expected fetch_athletes to return a response"
  # end

  # test "should fetch positions" do
  #   response = @client.fetch_positions
  #   assert_not_nil response, "Expected fetch_positions to return a response"
  # end
end
