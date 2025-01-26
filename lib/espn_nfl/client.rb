module EspnNfl
  # Client class to fetch data from ESPN NFL API
  # Reference: https://gist.github.com/nntrn/ee26cb2a0716de0947a0a4e9a157bc1c
  class Client
    attr_accessor :groups_teams_paths

    BASE_URL = "https://sports.core.api.espn.com/v2/sports/football/leagues/nfl"

    def initialize
      # NFL off-season is from February to July
      year = Time.now.month > 7 ? Time.now.year : Time.now.year - 1
      @groups_path = "/seasons/#{year}/types/2/groups" # 2 is for Regular Season
    end

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
      groups_created = []
      # First fetch conferences
      response = fetch(@groups_path)
      response.each do |group_ref|
        group = fetch_from_ref(group_ref["$ref"])
        group_model = save_group(group)
        groups_created << group_model

        # Second fetch divisions
        group_children = fetch_from_ref(group["children"]["$ref"])
        group_children.each do |group_child_ref|
          group_child = fetch_from_ref(group_child_ref["$ref"])
          group_child_model = save_group(group_child, group_model.id)
          groups_created << group_child_model
        end
      end
      groups_created
    end

    def fetch_groups_teams(groups_espn_ids)
      teams_created = []
      groups_espn_ids.each do |group_espn_id|
        group_teams_path = "#{@groups_path}/#{group_espn_id}/teams"
        group_teams_refs = fetch_from_ref(group_teams_path)
        group_teams_refs.each do |team_ref|
          team = fetch_from_ref(team_ref["$ref"])
          team_model = save_team(team, group_espn_id)
          teams_created << team_model
        end
      end
      teams_created
    end

    def fetch_athletes
      fetch("athletes")
    end

    def fetch_positions
      fetch("positions")
    end

    def fetch_all
      fetch_groups
      @groups_teams_paths.each do |group_id, teams_path|
        fetch_teams
      end
      fetch_teams
      fetch_athletes
      fetch_positions
    end

    private
      def fetch_from_ref(ref)
        path = ref.sub("http", "https").sub(BASE_URL, "")
        fetch(path)
      end

      def save_model(model_instance)
        if model_instance.save
          Rails.logger.info "Save model: #{model_instance.class.name}"
        else
          raise StandardError, "Error saving model: #{model_instance.errors.full_messages}"
        end
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
        save_model(group_model)
        group_model
      end

      def save_team(team, group_espn_id)
        team_model = Team.new(
          espn_id: team["id"],
          name: team["name"],
          abbreviation: team["abbreviation"],
          is_active: true,
          group: Group.find_by(espn_id: group_espn_id) # Not the best way to do this
        )
        save_model(team_model)
      end
  end
end
