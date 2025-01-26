module EspnNfl
  # Client class to fetch data from ESPN NFL API
  # Reference: https://gist.github.com/nntrn/ee26cb2a0716de0947a0a4e9a157bc1c
  class Client
    BASE_URL = "https://sports.core.api.espn.com/v2/sports/football/leagues/nfl"
    def fetch(endpoint)
      url = URI("#{BASE_URL}#{endpoint}?limit=1000")
      response = Net::HTTP.get_response(url)

      # If response status is not 200, raise an error
      raise StandardError, "Error fetching data: #{response.body}" unless response.code == "200"
      response_json = JSON.parse(response.body)
      if response_json.key?("items")
        response_parsed = response_json["items"]
      else
        response_parsed = response_json
      end

      return response_parsed unless response_json.key?("pageIndex") && response_json["pageIndex"] < response_json["pageCount"]

      response_parsed + fetch("#{endpoint}?page=#{response_json["pageIndex"] + 1}")
    end

    def fetch_groups
      # NFL off-season is from February to July
      year = Time.now.month > 7 ? Time.now.year : Time.now.year - 1
      # First fetch conferences
      response = fetch("/seasons/#{year}/types/2/groups") # 2 is for Regular Season
      response.each do |group_reference|
        group = fetch_from_reference(group_reference["$ref"])
        group_model = save_group(group)

        group_children = fetch_from_reference(group["children"]["$ref"])
        group_children.each do |group_child_reference|
          group_child = fetch_from_reference(group_child_reference["$ref"])
          save_group(group_child, group_model.id)
        end
      end
    end

    def fetch_teams
    end

    def fetch_athletes
      fetch("athletes")
    end

    def fetch_positions
      fetch("positions")
    end

    private
      def fetch_from_reference(reference)
        path = reference.sub("http", "https").sub(BASE_URL, "")
        fetch(path)
      end

      def save_group(group, parent_id = nil)
        group_model = Group.new(
          espn_id: group["id"],
          name: group["name"],
          abbreviation: group["abbreviation"],
          is_conference: group["isConference"],
          is_active: true,
          parent_id: parent_id
        )
        if group_model.save
          Rails.logger.info "Save group: #{group["name"]}"
        else
          raise StandardError, "Error saving group: #{group_model.errors.full_messages}"
        end
        group_model
      end
  end
end
