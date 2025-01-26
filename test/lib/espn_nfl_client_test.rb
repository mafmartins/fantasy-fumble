require "test_helper"
require "minitest/mock"
require "mocks/espn_nfl_client_http_mock"

class EspnNflClientTest < ActiveSupport::TestCase
  def setup
    @client = EspnNfl::Client.new
  end

  test "should fetch groups and save them" do
    Net::HTTP.stub :get_response, EspnNflClientHttpMock.method(:get_response) do
      response = @client.fetch_groups
      assert_not_nil response, "Expected fetch_groups to return a response"

      assert Group.count == 2, "Expected 2 groups to be saved"
      parent_id = 0

      Group.where(espn_id: 8).first.tap do |group|
        assert_not_nil group, "Expected group with espn_id 8 to be saved"
        assert group.name == "American Football Conference", "Expected group name to be American Football Conference"
        assert group.abbreviation == "AFC", "Expected group abbreviation to be AFC"
        assert group.is_conference == true, "Expected group is_conference to be true"
        parent_id = group.id
      end

      Group.where(espn_id: 12).first.tap do |group|
        assert_not_nil group, "Expected group with espn_id 12 to be saved"
        assert group.name == "AFC North", "Expected group name to be AFC North"
        assert group.abbreviation == "NORTH", "Expected group abbreviation to be NORTH"
        assert group.is_conference == false, "Expected group is_conference to be false"
        assert group.parent_id == parent_id, "Expected group parent_id to be 1"
      end
    end
  end

  # test "should fetch teams" do
  #   response = @client.fetch_teams
  #   assert_not_nil response, "Expected fetch_teams to return a response"
  # end

  # test "should fetch athletes" do
  #   response = @client.fetch_athletes
  #   assert_not_nil response, "Expected fetch_athletes to return a response"
  # end

  # test "should fetch positions" do
  #   response = @client.fetch_positions
  #   assert_not_nil response, "Expected fetch_positions to return a response"
  # end
end
