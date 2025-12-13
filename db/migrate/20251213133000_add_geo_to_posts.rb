class AddGeoToPosts < ActiveRecord::Migration[7.1]
  def change
    add_column :posts, :latitude, :float
    add_column :posts, :longitude, :float
    add_column :posts, :location, :string
    add_index :posts, [:latitude, :longitude]
  end
end

