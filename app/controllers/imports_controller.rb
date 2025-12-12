class ImportsController < ApplicationController
  before_action :require_admin!
  skip_before_action :verify_authenticity_token, only: :create, if: -> { request.format.json? }

  def new
  end

  def create
    url = params[:url].to_s
    owner_email = params[:owner_email].to_s
    upload = params[:data_file]
    kind = params[:import_kind].presence || 'reddit_posts'

    if upload.present?
      blob = ActiveStorage::Blob.create_and_upload!(io: upload, filename: upload.original_filename, content_type: upload.content_type)
      if kind == 'instagram_users'
        ImportInstagramUsersJob.perform_later(blob_id: blob.signed_id)
      elsif kind == 'news_rss'
        ImportNewsRssJob.perform_later(blob_id: blob.signed_id)
      else
        ImportRedditJob.perform_later(blob_id: blob.signed_id, owner_email: owner_email.presence)
      end
    elsif url.present?
      if kind == 'instagram_users'
        ImportInstagramUsersJob.perform_later(url: url)
      elsif kind == 'news_rss'
        ImportNewsRssJob.perform_later(url: url)
      else
        ImportRedditJob.perform_later(url: url, owner_email: owner_email.presence)
      end
    else
      respond_to do |format|
        format.html { redirect_to new_import_path, alert: 'Provide a URL or upload a CSV/JSON file.' }
        format.json { render json: { error: 'url or file is required' }, status: :unprocessable_entity }
      end
      return
    end
    respond_to do |format|
      format.html { redirect_to root_path, notice: 'Import started. Check back in a bit.' }
      format.json { render json: { status: 'enqueued' }, status: :accepted }
    end
  end

  private
  def require_admin!
    token = request.headers['X-Admin-Token'].presence || params[:token].presence
    allowed_by_token = token.present? && ENV['ADMIN_TOKEN'].present? && ActiveSupport::SecurityUtils.secure_compare(token, ENV['ADMIN_TOKEN'])
    allowed_by_user = user_signed_in? && (ENV['ADMIN_EMAIL'].blank? || current_user.email.downcase == ENV['ADMIN_EMAIL'].downcase)
    return if allowed_by_token || allowed_by_user

    respond_to do |format|
      format.html { redirect_to login_path, alert: 'Not authorized' }
      format.json { render json: { error: 'unauthorized' }, status: :unauthorized }
    end
  end
end
