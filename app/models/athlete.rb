class Athlete < ApplicationRecord
  belongs_to :position
  belongs_to :team
end
