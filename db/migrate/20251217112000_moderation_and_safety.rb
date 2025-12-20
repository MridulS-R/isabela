class ModerationAndSafety < ActiveRecord::Migration[7.1]
  def change
    add_column :posts, :hidden, :boolean, null: false, default: false
    add_column :comments, :hidden, :boolean, null: false, default: false
    add_column :users, :banned, :boolean, null: false, default: false

    create_table :reports do |t|
      t.references :user, null: false, foreign_key: true # reporter
      t.string :reportable_type, null: false
      t.bigint :reportable_id, null: false
      t.integer :status, null: false, default: 0 # 0 open, 1 reviewing, 2 resolved, 3 rejected
      t.string :reason, null: false
      t.text :notes
      t.timestamps
    end
    add_index :reports, [:reportable_type, :reportable_id]

    create_table :blocks do |t|
      t.references :blocker, null: false, foreign_key: { to_table: :users }
      t.references :blocked, null: false, foreign_key: { to_table: :users }
      t.timestamps
    end
    add_index :blocks, [:blocker_id, :blocked_id], unique: true
  end
end

