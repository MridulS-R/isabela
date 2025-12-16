class CreateHomepageArticles < ActiveRecord::Migration[7.1]
  def change
    create_table :homepage_articles do |t|
      t.references :community, null: false, foreign_key: true
      t.integer :status, null: false, default: 0 # draft, scheduled, published, retired
      t.integer :slot, null: false, default: 1   # lead=1, secondary=2, brief=3
      t.integer :position, null: false, default: 0
      t.text :metadata_json
      t.text :content_html
      t.datetime :published_at
      t.datetime :unpublished_at
      t.integer :version, null: false, default: 1
      t.references :created_by, foreign_key: { to_table: :users }
      t.timestamps
    end
    add_index :homepage_articles, [:status, :published_at]
    add_index :homepage_articles, [:community_id, :status]
    add_index :homepage_articles, [:slot, :position]
  end
end

