class CreateFeeds < ActiveRecord::Migration[7.1]
  def change
    create_table :feeds do |t|
      t.string :url, null: false
      t.string :title
      t.boolean :active, null: false, default: true
      t.datetime :last_fetched_at
      t.text :last_error
      t.timestamps
    end
    add_index :feeds, :url, unique: true
  end
end

