class AddCommunityToPostsAndArticles < ActiveRecord::Migration[7.1]
  def change
    add_reference :posts, :community, foreign_key: true
    add_reference :articles, :community, foreign_key: true
    add_reference :posts, :parent_post, foreign_key: { to_table: :posts }, null: true
    add_column :posts, :comments_count, :integer, null: false, default: 0
    add_index :posts, [:community_id, :created_at]
    add_index :articles, [:community_id, :published_at]
  end
end

