class CreatePositions < ActiveRecord::Migration[8.0]
  def change
    create_table :positions do |t|
      t.integer :espn_id
      t.string :abbreviation, limit: 3
      t.string :name
      t.boolean :is_active
      t.references :position, foreign_key: { to_table: :positions }

      t.timestamps
    end
    add_index :positions, :name, unique: true
    add_index :positions, :abbreviation, unique: true
    add_index :positions, :espn_id, unique: true
  end
end
