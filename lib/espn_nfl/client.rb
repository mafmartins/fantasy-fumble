require "net/http"

module EspnNfl
  # Client class to fetch data from ESPN NFL API
  # Reference: https://gist.github.com/nntrn/ee26cb2a0716de0947a0a4e9a157bc1c
  class Client
    attr_accessor :groups_path, :positions_path

    BASE_URL = "https://sports.core.api.espn.com/v2/sports/football/leagues/nfl"

    def initialize(year = nil)
      # NFL off-season is from February to July
      year = year ? year : Time.now.month > 7 ? Time.now.year : Time.now.year - 1
      @groups_path = "/seasons/#{year}/types/2/groups" # 2 is for Regular Season
      @positions_path = "/positions"
    end

    def fetch(endpoint, page = 1)
      url = URI("#{BASE_URL}#{endpoint}?limit=1000&page=#{page}")
      response = Net::HTTP.get_response(url)

      raise StandardError, "Error fetching data: #{response.body}" unless response.code == "200"
      response_json = JSON.parse(response.body)
      if response_json.key?("items")
        response_parsed = response_json["items"]
      else
        response_parsed = response_json
      end

      return response_parsed unless response_json.key?("pageIndex") && response_json["pageIndex"] < response_json["pageCount"]

      response_parsed + fetch(endpoint, page + 1)
    end

    def fetch_from_ref(ref)
      path = ref.sub("http", "https").sub(BASE_URL, "")
      fetch(path)
    end

    def group_teams_path(group_id)
      "#{@groups_path}/#{group_id}/teams"
    end

    def team_athletes_path(team_id)
      "/teams/#{team_id}/athletes"
    end
  end
end
