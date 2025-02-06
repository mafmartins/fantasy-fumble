module EspnNfl
  class Updater
    def initialize
      @client = EspnNfl::Client.new
      @models_ids_cache = {
        Group.name => {},
        Team.name => {},
        Position.name => {},
        Athlete.name => {}
      }
    end

    def fetch_and_upsert_groups
      total_result = []
      groups = []
      groups_children_refs = {}

      response = @client.fetch(@client.groups_path)
      response.each do |group_ref|
        groups.push(@client.fetch_from_ref(group_ref["$ref"]))
        groups_children_refs[groups.last["id"]] = @client.fetch_from_ref(groups.last["children"]["$ref"])
      end
      groups_result = upsert_groups(groups)
      total_result << groups_result

      raise StandardError, "Error upserting groups" unless total_result.length == groups.length

      groups_children_refs.each do |group_espn_id, group_children_ref|
        group_children = group_children_ref.map do |group_child_ref|
          @client.fetch_from_ref(group_child_ref["$ref"])
        end
        group_id = groups_result.to_a.find { |group| group["espn_id"] == group_espn_id.to_i }["id"]
        group_children_result = upsert_groups(group_children, group_id)
        total_result << group_children_result

        raise StandardError, "Error upserting group children" unless group_children_result.length == group_children.length
      end
      total_result
    end

    def fetch_and_upsert_groups_teams(groups_espn_ids)
      total_result = []
      groups_espn_ids.each do |group_espn_id|
        group_teams_refs = @client.fetch_from_ref(@client.group_teams_path(group_espn_id))
        group_teams_refs.each do |team_ref|
          team = @client.fetch_from_ref(team_ref["$ref"])
          team_result = upsert_team(team, group_espn_id)
          total_result << team_result
        end
      end
      total_result
    end

    def fetch_and_upsert_positions
      total_result = []
      position_refs = @client.fetch(@client.positions_path)
      position_refs.each do |position_ref|
        position = @client.fetch_from_ref(position_ref["$ref"])
        position_result = upsert_position(position)
        total_result << position_result
      end
      total_result
    end

    def fetch_and_upsert_teams_athletes(teams_espn_ids)
      total_result = []
      teams_espn_ids.each do |team_espn_id|
        team_athletes_refs = @client.fetch(@client.team_athletes_path(team_espn_id))
        team_athletes_refs.each do |team_athlete_ref|
          athlete = @client.fetch_from_ref(team_athlete_ref["$ref"])
          athlete_result = upsert_athlete(athlete, team_espn_id)
          total_result << athlete_result
        end
      end
    end

    private
      def cache_model_id(klass_name, model_espn_id, model_id)
        @models_ids_cache[klass_name][model_espn_id] = model_id
      end

      def upsert_model(klass, attributes)
        result = klass.upsert(attributes, unique_by: :espn_id, returning: [ :id, :espn_id ])
        # Throw an error if the upsert fails
        raise StandardError, "Error upserting model with ESPN ID: #{attributes[:espn_id]}" if result.empty?
        cache_model_id(klass.name, result.first["espn_id"], result.first["id"])
        result.first
      end

      def upsert_multiple_model(klass, attrs_list)
        result = klass.upsert_all(attrs_list, unique_by: :espn_id, returning: [ :id, :espn_id ])

        raise StandardError, "Error upserting multiple models" if result.empty?
        result.each do |result|
          cache_model_id(klass.name, result["espn_id"], result["id"])
        end
        result
      end

      def upsert_groups(groups, parent_id = nil)
        groups_attrs = groups.map do |group|
          {
            espn_id: group["id"],
            name: group["name"],
            abbreviation: group["abbreviation"],
            is_conference: group["isConference"],
            is_active: true,
            parent_id: parent_id
          }
        end
        upsert_multiple_model(Group, groups_attrs)
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
