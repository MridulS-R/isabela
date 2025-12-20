class CommunityFeedChannel < ApplicationCable::Channel
  def subscribed
    slug = params[:slug].to_s
    return reject if slug.blank?
    community = Community.find_by(slug: slug)
    return reject unless community
    stream_from "community:#{community.id}"
  end
end

