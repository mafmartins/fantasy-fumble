class CreateTeams < ActiveRecord::Migration[8.0]
  def change
    create_table :teams do |t|
      t.integer :espn_id
      t.string :slug
      t.string :abbreviation, limit: 3
      t.string :display_name
      t.string :short_display_name
      t.string :name
      t.string :nickname
      t.string :location
      t.string :color, limit: 6
      t.string :alternate_color, limit: 6
      t.string :logo
      t.boolean :is_active
      t.references :group, null: false, foreign_key: true

      t.timestamps
    end
  end
end
