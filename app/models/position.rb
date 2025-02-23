class Position < ApplicationRecord
  belongs_to :parent, class_name: "Position", foreign_key: "parent_id"
end
