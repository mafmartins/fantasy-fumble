require "test_helper"
require "minitest/mock"
require "mocks/espn_nfl_client_http_mock"

class EspnNflUpdaterTest < ActiveSupport::TestCase
  def setup
    @group_one = groups(:one)
    @team_one = teams(:one)
    @position_wr = positions(:wide_receiver)
    @client = EspnNfl::Client.new(2024)
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
      assert_nil groups[0][:id]
      assert_equal "American Football Conference", groups[0][:name]
      assert_equal "AFC", groups[0][:abbreviation]
      assert_equal true, groups[0][:is_conference]
      assert_equal true, groups[0][:is_active]
      assert_nil groups[0][:parent]
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
      assert_nil groups[0][:id]
      assert_equal "AFC North", groups[0][:name]
      assert_equal "NORTH", groups[0][:abbreviation]
      assert_equal false, groups[0][:is_conference]
      assert_equal true, groups[0][:is_active]
      assert_not_nil groups[0][:parent_espn_id]
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
      assert_nil groups[0][:id]
      assert_equal "American Football Conference", groups[0][:name]
      assert_equal "AFC", groups[0][:abbreviation]
      assert_equal true, groups[0][:is_conference]
      assert_equal true, groups[0][:is_active]
      assert_nil groups[0][:parent_espn_id]

      assert_nil groups[1][:id]
      assert_equal "AFC North", groups[1][:name]
      assert_equal "NORTH", groups[1][:abbreviation]
      assert_equal false, groups[1][:is_conference]
      assert_equal true, groups[1][:is_active]
      assert_equal 0, groups[1][:parent_espn_id]
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
      assert_nil positions[0][:id]
      assert_equal "Wide Receiver", positions[0][:name]
      assert_equal "WR", positions[0][:abbreviation]
      assert_equal true, positions[0][:is_active]
      assert_equal 70, positions[0][:parent_espn_id]
    end
  end
end
