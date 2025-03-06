class PointsCalculatorController < ApplicationController
  def index
    @page_name = "points_calculator"
    @teams = Team.all.order(:display_name)
    @athletes = Athlete.where(is_active: true).order(:display_name)
    @seasons = (2020..Date.current.year).to_a.reverse
    @weeks = (1..17).to_a
  end

  def calculate
    athletes_ids = params[:athletes]
    season = params[:season].to_i
    week = params[:week].to_i

    if athletes_ids.nil? || athletes_ids.empty? || season.nil? || week.nil? || !season || !week
      render json: { error: "Invalid params" }, status: :unprocessable_entity
      return
    end

    athletes = Athlete.eager_load(:team, :position).where(id: athletes_ids)
    if athletes.empty? || athletes.length != athletes_ids.length
      render json: { error: "Athletes not found" }, status: :not_found
      return
    end

    athletes_stats = get_athletes_stats(athletes, season, week)

    athletes = athletes.map do |athlete|
      {
        id: athlete.id,
        full_name: athlete.full_name,
        display_name: athlete.display_name,
        position: athlete.position.name,
        team: athlete.team.display_name,
        headshot: athlete.headshot,
        points_breakdown: athletes_stats[athlete.id],
        points_sum: athletes_stats[athlete.id].values.sum.round(2)
      }
    end
  end

  private
    def get_athletes_stats(athletes, season, week)
      engine = Fantasy::Engine.new(season, week)
      engine.calculate_athletes_points(athletes)
    end
end
