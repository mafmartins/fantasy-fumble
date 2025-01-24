class CreateGroups < ActiveRecord::Migration[8.0]
  def change
    create_table :groups do |t|
      t.integer :espn_id
      t.string :name
      t.string :abbreviation, limit: 3
      t.boolean :is_conference
      t.string :logo
      t.boolean :is_active
      t.references :parent, foreign_key: { to_table: :groups }

      t.timestamps
    end
    add_index :groups, :name, unique: true
  end
end
