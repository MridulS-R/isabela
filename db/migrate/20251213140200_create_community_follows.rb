class CreateCommunityFollows < ActiveRecord::Migration[7.1]
  def change
    create_table :community_follows do |t|
      t.references :user, null: false, foreign_key: true
      t.references :community, null: false, foreign_key: true
      t.timestamps
    end
    add_index :community_follows, [:user_id, :community_id], unique: true
  end
end

