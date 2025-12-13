class CreateTopicsAndPostTopics < ActiveRecord::Migration[7.1]
  def change
    create_table :topics do |t|
      t.references :community, null: false, foreign_key: true
      t.string :name, null: false
      t.string :slug, null: false
      t.integer :posts_count, null: false, default: 0
      t.timestamps
    end
    add_index :topics, [:community_id, :slug], unique: true
    add_index :topics, [:community_id, :posts_count]

    create_table :post_topics do |t|
      t.references :post, null: false, foreign_key: true
      t.references :topic, null: false, foreign_key: true
      t.timestamps
    end
    add_index :post_topics, [:post_id, :topic_id], unique: true
  end
end

