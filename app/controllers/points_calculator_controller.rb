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
    season_id = params[:season]
    week_id = params[:week]

    if athletes_ids.nil? || athletes_ids.empty? || season_id.nil? || week_id.nil?
      render json: { error: "Invalid params" }, status: :unprocessable_entity
      return
    end

    athletes = Athlete.where(id: athletes_ids)
    if athletes.empty? || athletes.length != athletes_ids.length
      render json: { error: "Athletes not found" }, status: :not_found
      return
    end

    athletes = athletes.map do |athlete|
      {
        id: athlete.id,
        full_name: athlete.full_name,
        display_name: athlete.display_name,
        position: athlete.position.name,
        team: athlete.team.display_name,
        headshot: athlete.headshot,
        points: 0
      }
    end
  end
end
