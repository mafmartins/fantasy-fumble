require "logger"

module EspnNfl
  class Updater
    def initialize
      @logger = Logger.new(STDOUT)
      @client = EspnNfl::Client.new
      @models_ids_cache = {
        Group.name => {},
        Team.name => {},
        Position.name => {},
        Athlete.name => {}
      }
    end

    def fetch_and_upsert_groups
      @logger.info("Fetching groups from ESPN NFL API...")

      total_result = []
      groups = []
      groups_children_refs = {}

      response = @client.fetch(@client.groups_path)
      response.each do |group_ref|
        groups.push(@client.fetch_from_ref(group_ref["$ref"]))
        groups_children_refs[groups.last["id"]] = @client.fetch_from_ref(groups.last["children"]["$ref"])
      end
      groups_result = upsert_groups(groups)
      total_result.push(*groups_result.to_a)

      raise StandardError, "Error upserting groups" unless total_result.length == groups.length

      groups_children_refs.each do |group_espn_id, group_children_ref|
        group_children = group_children_ref.map do |group_child_ref|
          @client.fetch_from_ref(group_child_ref["$ref"])
        end
        group_id = groups_result.to_a.find { |group| group["espn_id"] == group_espn_id.to_i }["id"]
        group_children_result = upsert_groups(group_children, group_id)
        total_result.push(*group_children_result.to_a)

        raise StandardError, "Error upserting group children" unless group_children_result.length == group_children.length
      end

      @logger.info("Finished fetching groups from ESPN NFL API. Result count: #{total_result.length}")

      total_result
    end

    def fetch_and_upsert_groups_teams(groups_espn_ids)
      @logger.info("Fetching teams from ESPN NFL API...")

      total_result = []
      groups_espn_ids.each do |group_espn_id|
        group_teams_refs = @client.fetch_from_ref(@client.group_teams_path(group_espn_id))
        teams = group_teams_refs.map do |team_ref|
        @client.fetch_from_ref(team_ref["$ref"])
        end
        total_result.push(*upsert_teams(teams, group_espn_id).to_a)

        raise StandardError, "Error upserting teams" unless total_result.length == teams.length
      end

      @logger.info("Finished fetching teams from ESPN NFL API. Result count: #{total_result.length}")

      total_result
    end

    def fetch_and_upsert_positions
      @logger.info("Fetching positions from ESPN NFL API...")

      total_result = []
      position_refs = @client.fetch(@client.positions_path)
      positions = position_refs.map do |position_ref|
        @client.fetch_from_ref(position_ref["$ref"])
      end
      total_result.push(*upsert_positions(positions).to_a)

      raise StandardError, "Error upserting positions" unless total_result.length == positions.length

      @logger.info("Finished fetching positions from ESPN NFL API. Result count: #{total_result.length}")

      total_result
    end

    def fetch_and_upsert_teams_athletes(teams_espn_ids)
      @logger.info("Fetching athletes from ESPN NFL API...")

      total_result = []
      teams_espn_ids.each do |team_espn_id|
        team_athletes_refs = @client.fetch(@client.team_athletes_path(team_espn_id))
        team_athletes = team_athletes_refs.map do |team_athlete_ref|
          @client.fetch_from_ref(team_athlete_ref["$ref"])
        end
        total_result.push(*upsert_athletes(team_athletes, team_espn_id).to_a)

        raise StandardError, "Error upserting athletes" unless total_result.length == team_athletes.length
      end

      @logger.info("Finished fetching athletes from ESPN NFL API. Result count: #{total_result.length}")

      total_result
    end

    def fetch_and_upsert_all
      @logger.info("Starting to fetch data from ESPN NFL API...")

      total_result = []
      ActiveRecord::Base.transaction do
        groups_result = fetch_and_upsert_groups
        positions_result = fetch_and_upsert_positions
        groups_teams_result = fetch_and_upsert_groups_teams(groups_result.map { |group| group["espn_id"] })
        teams_athletes_result = fetch_and_upsert_teams_athletes(groups_teams_result.map { |team| team["espn_id"] })

        total_result.push(*groups_result)
        total_result.push(*positions_result)
        total_result.push(*groups_teams_result)
        total_result.push(*teams_athletes_result)
      end

      @logger.info("Finished fetching data from ESPN NFL API. Result count: #{total_result.length}")

      total_result
    end

    private
      def cache_model_id(klass_name, model_espn_id, model_id)
        @models_ids_cache[klass_name][model_espn_id] = model_id
      end

      def upsert_multiple_model(klass, attrs_list)
        result = klass.upsert_all(attrs_list, unique_by: :espn_id, returning: [ :id, :espn_id ])

        raise StandardError, "Error upserting multiple models" if result.length != attrs_list.length
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

      def upsert_teams(teams, group_espn_id)
        teams_attrs = teams.map do |team|
          {
            espn_id: team["id"],
            name: team["name"],
            abbreviation: team["abbreviation"],
            is_active: team["isActive"],
            group_id: @models_ids_cache.dig(Group.class.name, group_espn_id) || Group.find_by(espn_id: group_espn_id).id
          }
        end
        upsert_multiple_model(Team, teams_attrs)
      end

      def upsert_positions(positions, parent_id = nil)
        positions_attrs = positions.map do |position|
          if position.dig("parent")
            parent_espn_id = position["parent"]["$ref"].split("/").last.to_i
            parent_position_id = @models_ids_cache.dig(Position.class.name, parent_espn_id) || Position.find_by(espn_id: parent_espn_id).id
          else
            parent_position_id = nil
          end
          {
            espn_id: position["id"],
            name: position["name"],
            abbreviation: position["abbreviation"],
            is_active: true,
            parent_id: parent_position_id
          }
        end
        upsert_multiple_model(Position, positions_attrs)
      end

      def upsert_athletes(athletes, team_espn_id)
        athletes_attrs = athletes.map do |athlete|
          position_id = @models_ids_cache.dig(Position.class.name, athlete["position"]["id"]) || Position.find_by(espn_id: athlete["position"]["id"]).id
          team_id = @models_ids_cache.dig(Team.class.name, athlete["team"]["id"]) || Team.find_by(espn_id: team_espn_id).id
          {
            espn_id: athlete["id"],
            first_name: athlete["firstName"],
            last_name: athlete["lastName"],
            display_name: athlete["displayName"],
            jersey: athlete["jersey"],
            is_active: athlete["active"],
            position_id: position_id,
            team_id: team_id
          }
        end
        upsert_multiple_model(Athlete, athletes_attrs)
      end
  end
end
