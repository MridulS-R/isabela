class CreateCommunities < ActiveRecord::Migration[7.1]
  def change
    create_table :communities do |t|
      t.string :name, null: false
      t.string :slug, null: false
      t.text :description
      t.integer :visibility, null: false, default: 0 # 0 public, 1 private
      t.references :created_by, null: false, foreign_key: { to_table: :users }
      t.integer :posts_count, null: false, default: 0
      t.integer :followers_count, null: false, default: 0
      t.integer :articles_count, null: false, default: 0
      t.timestamps
    end
    add_index :communities, :slug, unique: true
    add_index :communities, :created_by_id
  end
end

