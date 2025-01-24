class CreatePositions < ActiveRecord::Migration[8.0]
  def change
    create_table :positions do |t|
      t.string :abbreviation, limit: 3
      t.string :name
      t.boolean :is_offense
      t.boolean :is_defense
      t.boolean :is_special_teams
      t.boolean :is_active

      t.timestamps
    end
  end
end
