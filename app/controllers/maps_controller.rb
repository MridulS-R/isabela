class MapsController < ApplicationController
  def index
  end

  def data
    # Aggregate post counts by approximate location (rounded to ~0.01 degrees)
    counts = Post.where.not(latitude: nil, longitude: nil)
                 .group(Arel.sql('ROUND(latitude, 2), ROUND(longitude, 2)'))
                 .count

    points = counts.map do |(lat_lng, count)|
      lat, lng = if lat_lng.is_a?(Array)
        lat_lng
      else
        # Some adapters return a string key; try to split
        lat_lng.to_s.split(',').map(&:to_f)
      end
      { lat: lat.to_f, lng: lng.to_f, count: count.to_i }
    end

    render json: { points: points }
  end
end

