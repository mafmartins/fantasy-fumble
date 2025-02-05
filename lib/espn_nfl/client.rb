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
      @models_ids_cache = {
        Group.name => {},
        Team.name => {},
        Position.name => {},
        Athlete.name => {}
      }
    end

    def fetch(endpoint, page = 1)
      url = URI("#{BASE_URL}#{endpoint}?limit=1000&page=#{page}")
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

      response_parsed + fetch(endpoint, page + 1)
    end

    def fetch_groups
      total_result = []
      # First fetch conferences
      response = fetch(@groups_path)
      response.each do |group_ref|
        group = fetch_from_ref(group_ref["$ref"])
        group_result = upsert_group(group)
        total_result << group_result

        # Second fetch divisions
        group_children = fetch_from_ref(group["children"]["$ref"])
        group_children.each do |group_child_ref|
          group_child = fetch_from_ref(group_child_ref["$ref"])
          group_child_result = upsert_group(group_child, group_result["id"])
          total_result << group_child_result
        end
      end
      total_result
    end

    def fetch_groups_teams(groups_espn_ids)
      total_result = []
      groups_espn_ids.each do |group_espn_id|
        group_teams_path = "#{@groups_path}/#{group_espn_id}/teams"
        group_teams_refs = fetch_from_ref(group_teams_path)
        group_teams_refs.each do |team_ref|
          team = fetch_from_ref(team_ref["$ref"])
          team_result = upsert_team(team, group_espn_id)
          total_result << team_result
        end
      end
      total_result
    end

    def fetch_positions
      total_result = []
      positions_path = "/positions"
      position_refs = fetch(positions_path)
      position_refs.each do |position_ref|
        position = fetch_from_ref(position_ref["$ref"])
        position_result = upsert_position(position)
        total_result << position_result
      end
      total_result
    end

    def fetch_teams_athletes(teams_espn_ids)
      total_result = []
      teams_espn_ids.each do |team_espn_id|
        team_path = "/teams/#{team_espn_id}/athletes"
        team_athletes_refs = fetch_from_ref(team_path)
        team_athletes_refs.each do |team_athlete_ref|
          athlete = fetch_from_ref(team_athlete_ref["$ref"])
          athlete_result = upsert_athlete(athlete, team_espn_id)
          total_result << athlete_result
        end
      end
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

      def cache_model_id(klass_name, model_espn_id, model_id)
        @models_ids_cache[klass_name][model_espn_id] = model_id
      end

      def save_model(model_instance)
        # TODO: Change this to an upsert, maybe using the upsert_all method
        if model_instance.save
          Rails.logger.info "Save model: #{model_instance.class.name}"
        else
          raise StandardError, "Error saving model: #{model_instance.errors.full_messages}"
        end
      end

      def upsert_model(klass, attributes)
        result = klass.upsert(attributes, unique_by: :espn_id, returning: [ :id, :espn_id ])
        # Throw an error if the upsert fails
        raise StandardError, "Error upserting model with ESPN ID: #{attributes[:espn_id]}" if result.empty?
        cache_model_id(klass.name, result.first["espn_id"], result.first["id"])
        result.first
      end

      def upsert_group(group, parent_id = nil)
        group_attrs = {
          espn_id: group["id"],
          name: group["name"],
          abbreviation: group["abbreviation"],
          is_conference: group["isConference"],
          is_active: true,
          parent_id: parent_id
        }
        upsert_model(Group, group_attrs)
      end

      def upsert_team(team, group_espn_id)
        team_attrs = {
          espn_id: team["id"],
          name: team["name"],
          abbreviation: team["abbreviation"],
          is_active: team["isActive"],
          group_id: @models_ids_cache.dig(Group.class.name, group_espn_id) || Group.find_by(espn_id: group_espn_id).id
        }
        upsert_model(Team, team_attrs)
      end

      def upsert_position(position, parent_id = nil)
        if position.dig("parent")
          parent_espn_id = position["parent"]["$ref"].split("/").last.to_i
          parent_position_id = @models_ids_cache.dig(Position.class.name, parent_espn_id) || Position.find_by(espn_id: parent_espn_id).id
        else
          parent_position_id = nil
        end
        position = {
          espn_id: position["id"],
          name: position["name"],
          abbreviation: position["abbreviation"],
          is_active: true,
          parent_id: parent_position_id
        }
        upsert_model(Position, position)
      end

      def upsert_athlete(athlete, team_espn_id)
        position_id = @models_ids_cache.dig(Position.class.name, athlete["position"]["id"]) || Position.find_by(espn_id: athlete["position"]["id"]).id
        team_id = @models_ids_cache.dig(Team.class.name, athlete["team"]["id"]) || Team.find_by(espn_id: team_espn_id).id
        athlete_attrs = {
          espn_id: athlete["id"],
          first_name: athlete["firstName"],
          last_name: athlete["lastName"],
          display_name: athlete["displayName"],
          jersey: athlete["jersey"],
          is_active: athlete["active"],
          position_id: position_id,
          team_id: team_id
        }
        upsert_model(Athlete, athlete_attrs)
      end
  end
end
