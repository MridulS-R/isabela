class CreateNewsSources < ActiveRecord::Migration[7.1]
  def change
    create_table :news_sources do |t|
      t.string :name, null: false
      t.references :community, null: false, foreign_key: true
      t.integer :kind, null: false, default: 1 # 0:rss, 1:website, 2:sitemap
      t.text :list_urls # JSON array of URLs
      t.string :link_selector
      t.string :body_selector
      t.string :date_selector
      t.boolean :active, null: false, default: true
      t.datetime :last_crawled_at
      t.text :last_error
      t.timestamps
    end
    add_index :news_sources, [:community_id, :active]
  end
end

