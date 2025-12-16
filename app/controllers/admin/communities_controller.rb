class Admin::CommunitiesController < ApplicationController
  before_action :require_admin!

  def create
    name = params[:name].to_s.strip
    slug = params[:slug].to_s.strip.downcase
    if name.blank? || slug.blank?
      return redirect_to admin_homepage_articles_path, alert: 'Name and slug are required.'
    end
    community = Community.find_or_initialize_by(slug: slug)
    community.name ||= name
    community.description ||= ''
    community.visibility ||= :publicly_visible
    community.created_by ||= current_user
    if community.save
      redirect_to admin_homepage_articles_path, notice: 'Community created.'
    else
      redirect_to admin_homepage_articles_path, alert: community.errors.full_messages.to_sentence
    end
  end
end

