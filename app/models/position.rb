class Position < ApplicationRecord
  belongs_to :parent, class_name: "Position", foreign_key: "parent_id"
  has_many :children, class_name: "Position", foreign_key: "parent_id"

  def all_children
    children.flat_map do |child|
      [ child ] + child.all_children
    end
  end

  def all_parents
    return [] unless parent

    [ parent ] + parent.all_parents
  end
end
