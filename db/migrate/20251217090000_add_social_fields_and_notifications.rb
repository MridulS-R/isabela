class AddSocialFieldsAndNotifications < ActiveRecord::Migration[7.1]
  def change
    # Post kinds and visibility
    add_column :posts, :kind, :integer, null: false, default: 0 # 0 original, 1 repost, 2 quote
    add_column :posts, :visibility, :integer, null: false, default: 0 # 0 public, 1 followers, 2 community
    add_index :posts, :kind
    add_index :posts, :visibility

    # Notifications
    create_table :notifications do |t|
      t.references :user, null: false, foreign_key: true # recipient
      t.references :actor, null: false, foreign_key: { to_table: :users }
      t.string :action, null: false # like, comment, repost, follow, mention
      t.references :notifiable, polymorphic: true, null: false
      t.datetime :read_at
      t.timestamps
    end
    add_index :notifications, [:user_id, :created_at]
  end
end

