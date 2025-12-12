class AddFieldsToArticles < ActiveRecord::Migration[7.1]
  def change
    add_column :articles, :url, :string
    add_column :articles, :source, :string
    add_index :articles, :url, unique: true
  end
end

