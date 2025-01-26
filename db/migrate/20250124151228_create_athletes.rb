class CreateAthletes < ActiveRecord::Migration[8.0]
  def change
    create_table :athletes do |t|
      t.integer :espn_id
      t.string :first_name
      t.string :last_name
      t.string :full_name
      t.string :display_name
      t.string :short_name
      t.integer :weight
      t.integer :height
      t.integer :age
      t.date :date_of_birth
      t.integer :experience_years
      t.integer :jersey
      t.string :college_abbreviation, limit: 3
      t.string :headshot
      t.boolean :is_active
      t.references :position, null: false, foreign_key: true
      t.references :team, null: false, foreign_key: true

      t.timestamps
    end
    add_index :athletes, :espn_id, unique: true
  end
end
