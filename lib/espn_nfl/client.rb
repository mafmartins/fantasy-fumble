require "net/http"
require "typhoeus"
require "logger"

module EspnNfl
  # Client class to fetch data from ESPN NFL API
  # Reference: https://gist.github.com/nntrn/ee26cb2a0716de0947a0a4e9a157bc1c
  class Client
    attr_accessor :groups_path, :positions_path

    BASE_URL = "https://sports.core.api.espn.com/v2/sports/football/leagues/nfl"

    def initialize(year = nil)
      @logger = Logger.new(STDOUT)
      @hydra = Typhoeus::Hydra.hydra
      # NFL off-season is from February to July
      @year = year ? year : Time.now.month > 7 ? Time.now.year : Time.now.year - 1
      @groups_path = "/seasons/#{@year}/types/2/groups" # 2 is for Regular Season
      @positions_path = "/positions"
    end

    def fetch(path, page = 1)
      url = path_to_url(path, page)

      @logger.info("Fetching data from #{url}")

      response = Net::HTTP.get_response(url)

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

    def fetch_from_ref(ref)
      fetch(ref_to_path(ref))
    end

    def fetch_from_refs(refs)
      @logger.info("Fetching data from #{refs.length} refs")
      requests = refs.map do |ref|
        # Typhoeus does not support URI stubsn that's why we need to convert the ref URI resukt to a string
        # https://github.com/typhoeus/typhoeus/issues/662
        url = ref_to_url(ref).to_s
        @logger.info("Queueing request for #{url}")
        request = Typhoeus::Request.new(url)
        @hydra.queue(request)
        request
      end

      @hydra.run
      @logger.info("Finished fetching data from refs")

      requests.map do |request|
        raise StandardError, "Error fetching data: #{request.response.body}" unless request.response.code == 200
        JSON.parse(request.response.body)
      end
    end

    def group_teams_path(group_id)
      "#{@groups_path}/#{group_id}/teams"
    end

    def team_athletes_path(team_id)
      "/seasons/#{@year}/teams/#{team_id}/athletes"
    end

    def ref_to_path(ref)
      ref.sub("http", "https").sub(BASE_URL, "")
    end

    def path_to_url(path, page = 1)
      URI("#{BASE_URL}#{path}?limit=1000&page=#{page}")
    end

    def ref_to_url(ref)
      path_to_url(ref_to_path(ref))
    end
  end
end
