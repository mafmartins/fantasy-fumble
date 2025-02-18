class PointsCalculatorController < ApplicationController
  def index
    @page_name = "points_calculator"
    @teams = Team.all.order(:display_name)
    @athletes = Athlete.where(is_active: true).order(:display_name)
    @seasons = (2020..Date.current.year).to_a.reverse
    @weeks = (1..17).to_a
  end

  def calculate
    debugger
  end
end
