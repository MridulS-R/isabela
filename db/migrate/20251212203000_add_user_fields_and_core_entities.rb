class AddUserFieldsAndCoreEntities < ActiveRecord::Migration[7.1]
  def change
    change_table :users do |t|
      t.string :username
      t.text :bio
    end
    add_index :users, :username, unique: true

    create_table :posts do |t|
      t.references :user, null: false, foreign_key: true
      t.text :caption
      t.integer :likes_count, default: 0, null: false
      t.timestamps
    end

    create_table :tags do |t|
      t.string :name, null: false
      t.timestamps
    end
    add_index :tags, :name, unique: true

    create_table :taggings do |t|
      t.references :post, null: false, foreign_key: true
      t.references :tag, null: false, foreign_key: true
      t.timestamps
    end
    add_index :taggings, [:post_id, :tag_id], unique: true

    create_table :likes do |t|
      t.references :user, null: false, foreign_key: true
      t.references :post, null: false, foreign_key: true
      t.timestamps
    end
    add_index :likes, [:user_id, :post_id], unique: true

    create_table :comments do |t|
      t.references :user, null: false, foreign_key: true
      t.references :post, null: false, foreign_key: true
      t.text :body, null: false
      t.timestamps
    end
  end
end
