module Fantasy
  class Engine
    def initialize(season, week, points_system_type = FantasyScoringType.standard.name)
      @season = season
      @week = week
      @client = EspnNfl::Client.new(season)
      @points_system_type = points_system_type
      @points_systems = JSON.load_file(Rails.root.join("lib", "fantasy", "config", "points_systems.json"), symbolize_names: true)
      @points_formulas = JSON.load_file(Rails.root.join("lib", "fantasy", "config", "espn_stats_mapping.json"), symbolize_names: true)
    end

    def calculate_points(athlete, stats)
      points = 0

      # Athlete can be an offense, defense/special teams or kicker
      points_category = nil
      case athlete.position.abbreviation
      when "QB", "RB", "WR", "TE"
        points_category = :offense
      when "K"
        points_category = :kicking
      else
        points_category = :defense
      end

      @points_systems[@points_system_type][points_category].each_with_object({}) do |(name, value), h|
        formula_stats = @points_formulas[points_category][name][:espn_stats_names]
        if formula_stats.length == 1
          h[name.to_sym] = (value * stats[formula_stats.first.to_sym][:value]).round(2)
        else
          stat_points = formula_stats.map do |stat|
            stat[0] != "-" ? stats[stat.to_sym][:value] : -stats[stat[1..].to_sym][:value]
          end
          h[name.to_sym] = (value * stat_points.reduce(:+)).round(2)
        end
      end
    end

    def calculate_athletes_points(athletes)
      athletes_espn_ids = athletes.map { |athlete| athlete.espn_id }
      teams_espn_ids = athletes.map { |athlete| athlete.team.espn_id }
      eventlogs = @client.fetch_athletes_eventlog(athletes_espn_ids)
      events_espn_ids = eventlogs.map do |eventlog|
        @client.get_id_from_event_ref(eventlog[@week - 1][:event_ref])
      end
      ids = events_espn_ids.zip(teams_espn_ids, athletes_espn_ids)
      stats_list = @client.fetch_athletes_stats(ids)
      athletes.zip(stats_list).map { |athlete, stats| [ athlete.id, calculate_points(athlete, stats) ] }.to_h
    end
  end
end
