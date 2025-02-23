require "net/http"
require "typhoeus"
require "logger"

##
# Module to fetch data from ESPN NFL API
#
# @see https://gist.github.com/nntrn/ee26cb2a0716de0947a0a4e9a157bc1c
module EspnNfl
  class Client
    attr_reader :groups_path, :positions_path

    BASE_URL = "https://sports.core.api.espn.com/v2/sports/football/leagues/nfl"

    ##
    # Constructor
    # @param [Integer] year (default: current year)
    # @param [Boolean] test (default: false)
    # @return [EspnNfl::Client]
    def initialize(year = nil, test = false)
      @logger = Rails.logger
      @hydra = Typhoeus::Hydra.hydra
      # NFL off-season is from February to July
      @year = year ? year : Time.now.month > 7 ? Time.now.year : Time.now.year - 1
      @test = test
      @groups_path = "/seasons/#{@year}/types/2/groups" # 2 is for Regular Season
      @positions_path = "/positions"
      @teams_path = "/seasons/#{@year}/teams"
      @athletes_path = "/seasons/#{@year}/athletes"
    end

    ##
    # Fetches groups from the API
    # @param [Array<Integer>] groups_ids
    # @return [Array<Hash>] Array of groups
    def fetch_groups(groups_ids)
      groups_responses = fetch_multiple(groups_ids.map { |group_id| group_path(group_id) })

      groups_responses.map do |group_response|
        parent_espn_id = get_id_from_group_ref(group_response["parent"]["$ref"]) if group_response.key?("parent")
        {
          espn_id: group_response["id"].to_i,
          name: group_response["name"],
          abbreviation: group_response["abbreviation"],
          is_conference: group_response["isConference"],
          is_active: true,
          parent_espn_id: parent_espn_id
        }
      end
    end

    ##
    # Fetches positions from the API
    # @param [Integer] positions_ids
    # @return [Array<Hash>] Array of positions
    def fetch_positions(positions_ids)
      positions_responses = fetch_multiple(positions_ids.map { |position_id| position_path(position_id) })

      positions_responses.map do |position_response|
        parent_espn_id = get_id_from_position_ref(position_response["parent"]["$ref"]) if position_response.key?("parent")
        {
          espn_id: position_response["id"].to_i,
          name: position_response["name"],
          abbreviation: position_response["abbreviation"],
          is_active: true,
          parent_espn_id: parent_espn_id
        }
      end
    end

    ##
    # Fetches teams from the API
    # @param [Array<Integer>] teams_ids
    # @return [Array<Hash>] Array of teams
    def fetch_teams(teams_ids)
      teams_responses = fetch_multiple(teams_ids.map { |team_id| team_path(team_id) })

      teams_responses.map do |team_response|
        group_espn_id = get_id_from_group_ref(team_response["groups"]["$ref"])
        {
          espn_id: team_response["id"].to_i,
          slug: team_response["slug"],
          abbreviation: team_response["abbreviation"],
          display_name: team_response["displayName"],
          short_display_name: team_response["shortDisplayName"],
          name: team_response["name"],
          nickname: team_response["nickname"],
          location: team_response["location"],
          color: team_response["color"],
          alternate_color: team_response["alternateColor"],
          logo: team_response.dig("logos", 0, "href"),
          is_active: team_response["isActive"],
          group_espn_id: group_espn_id
        }
      end
    end

    ##
    # Fetches athletes from the API
    # @param [Array<Integer>] athletes_ids
    # @return [Array<Hash>] Array of athletes
    def fetch_athletes(athletes_ids)
      athletes_responses = fetch_multiple(athletes_ids.map { |athlete_id| athlete_path(athlete_id) })

      athletes_responses.map do |athlete_response|
        position_id = get_id_from_position_ref(athlete_response["position"]["$ref"])
        team_espn_id = get_id_from_team_ref(athlete_response["team"]["$ref"])
        {
          espn_id: athlete_response["id"].to_i,
          first_name: athlete_response["firstName"],
          last_name: athlete_response["lastName"],
          full_name: athlete_response["fullName"],
          display_name: athlete_response["displayName"],
          short_name: athlete_response["shortName"],
          weight: athlete_response["weight"],
          height: athlete_response["height"],
          age: athlete_response["age"],
          date_of_birth: athlete_response["dateOfBirth"],
          experience_years: athlete_response["experience"].dig("years"),
          jersey: athlete_response["jersey"].to_i,
          headshot: athlete_response.dig("headshot", "href"),
          is_active: athlete_response["active"],
          position_espn_id: position_id,
          team_espn_id: team_espn_id
        }
      end
    end

    ##
    # Generic fetch method to fetch data from the API
    # @param [String] path
    # @param [Integer] page (default: 1)
    # @return [Array<Hash>] Array of responses
    def fetch(path, page = 1)
      url = path_to_url(path, page)

      @logger.info("Fetching data from #{url}")

      response = Net::HTTP.get_response(url)

      raise StandardError, "Test mode is enabled but no mock response found for #{url}" if @test && response.try(:mock).nil?

      raise StandardError, "Error fetching data: #{response.body}" unless response.code == "200"

      response_json = JSON.parse(response.body)
      if response_json.key?("items")
        response_parsed = response_json["items"]
      else
        response_parsed = response_json
      end

      return response_parsed unless response_json.key?("pageIndex") && response_json["pageIndex"] < response_json["pageCount"]

      response_parsed + fetch(path, page + 1)
    end

    ##
    # Fetches data from multiple paths
    # @param [Array<String>] paths
    # @return [Array<Hash>] Array of responses
    def fetch_multiple(paths)
      @logger.info("Fetching data from #{paths.length} paths")
      requests = paths.map do |path|
        # Typhoeus does not support URI stubsn that's why we need to convert the ref URI resukt to a string
        # https://github.com/typhoeus/typhoeus/issues/662
        url = path_to_url(path).to_s
        @logger.info("Queueing request for #{url}")
        request = Typhoeus::Request.new(url)
        @hydra.queue(request)
        request
      end

      @hydra.run
      @logger.info("Finished fetching data from paths")

      requests.map do |request|
        raise StandardError, "Test mode is enabled but no mock response found for #{request.base_url}" if @test && request.response.try(:mock).nil?

        raise StandardError, "Error fetching data: #{request.response.body}" unless request.response.code == 200

        JSON.parse(request.response.body)
      end
    end

    ##
    # Fetches data from a ref
    # @param [String] ref
    # @return [Hash] Response
    def fetch_from_ref(ref)
      fetch(ref_to_path(ref))
    end

    ##
    # Fetches data from multiple refs
    # @param [Array<String>] refs
    # @return [Array<Hash>] Array of responses
    def fetch_from_refs(refs)
      fetch_multiple(refs.map { |ref| ref_to_path(ref) })
    end

    # Utils

    ##
    # Converts a ref to a path
    # @param [String] ref
    # @return [String]
    def ref_to_path(ref)
      # TODO Improve this to keep the query params
      ref.sub("http", "https").sub(BASE_URL, "").split("?").first
    end

    ##
    # Converts a path to a URL
    # @param [String] path
    # @param [Integer] page (default: 1)
    # @return [URI]
    def path_to_url(path, page = 1)
      URI("#{BASE_URL}#{path}?limit=1000&page=#{page}")
    end

    ##
    # Converts a ref to a URL
    # @param [String] ref
    # @return [URI]
    def ref_to_url(ref)
      path_to_url(ref_to_path(ref))
    end

    ##
    # Converts a group ID to a path
    # @param [Integer] group_id
    # @return [String]
    def group_path(group_id)
      "#{@groups_path}/#{group_id}"
    end

    ##
    # Converts a group ID to a path
    # @param [Integer] group_id
    # @return [String]
    def group_teams_path(group_id)
      "#{@groups_path}/#{group_id}/teams"
    end

    ##
    # Converts a position ID to a path
    # @param [Integer] position_id
    # @return [String]
    def position_path(position_id)
      "#{@positions_path}/#{position_id}"
    end

    ##
    # Converts a team ID to a path
    # @param [Integer] team_id
    # @return [String]
    def team_path(team_id)
      "#{@teams_path}/#{team_id}"
    end

    ##
    # Converts a team ID to a path
    # @param [Integer] team_id
    # @return [String]
    def team_athletes_path(team_id)
      "/seasons/#{@year}/teams/#{team_id}/athletes"
    end

    ##
    # Converts an athlete ID to a path
    # @param [Integer] athlete_id
    # @return [String]
    def athlete_path(athlete_id)
      "#{@athletes_path}/#{athlete_id}"
    end

    ##
    # Converts an athlete ID to a path
    # @param [Integer] athlete_id
    # @return [String]
    def athletes_eventlog_path(athlete_id)
      "/seasons/#{@year}/athletes/#{athlete_id}/eventlog"
    end

    ##
    # Retrieves the ESPN ID from a group ref
    # @param [String] ref
    # @return [Integer]
    def get_id_from_group_ref(ref)
      ref.match(/groups\/(\d+)/)[1].to_i
    end

    ##
    # Retrieves the ESPN ID from a position ref
    # @param [String] ref
    # @return [Integer]
    def get_id_from_position_ref(ref)
      ref.match(/positions\/(\d+)/)[1].to_i
    end

    ##
    # Retrieves the ESPN ID from a team ref
    # @param [String] ref
    # @return [Integer]
    def get_id_from_team_ref(ref)
      ref.match(/teams\/(\d+)/)[1].to_i
    end

    ##
    # Retrieves the ESPN ID from an athlete ref
    # @param [String] ref
    # @return [Integer]
    def get_id_from_athlete_ref(ref)
      ref.match(/athletes\/(\d+)/)[1].to_i
    end
  end
end
