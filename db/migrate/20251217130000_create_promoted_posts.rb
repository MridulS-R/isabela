class CreatePromotedPosts < ActiveRecord::Migration[7.1]
  def change
    create_table :promoted_posts do |t|
      t.references :post, null: false, foreign_key: true
      t.boolean :active, null: false, default: true
      t.integer :weight, null: false, default: 1
      t.integer :impressions_count, null: false, default: 0
      t.integer :clicks_count, null: false, default: 0
      t.datetime :last_shown_at
      t.timestamps
    end
    add_index :promoted_posts, [:active, :last_shown_at]
  end
end

