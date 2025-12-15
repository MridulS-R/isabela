class AddRememberAndUserSessions < ActiveRecord::Migration[7.1]
  def change
    add_column :users, :remember_token_digest, :string
    add_column :users, :remember_created_at, :datetime
    add_index :users, :remember_token_digest

    create_table :user_sessions do |t|
      t.references :user, null: false, foreign_key: true
      t.string :token_digest, null: false
      t.string :user_agent
      t.string :ip
      t.datetime :last_seen_at
      t.timestamps
    end
    add_index :user_sessions, :token_digest, unique: true
  end
end

