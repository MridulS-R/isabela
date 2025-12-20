class ReportsController < ApplicationController
  before_action :require_login

  def new
    @reportable_type = params[:type]
    @reportable_id = params[:id]
  end

  def create
    type = params[:reportable_type].to_s
    id = params[:reportable_id].to_s
    reason = params[:reason].to_s.strip
    klass = { 'post' => Post, 'comment' => Comment, 'user' => User }[type]
    return redirect_back fallback_location: root_path, alert: 'Invalid report' unless klass && reason.present?
    obj = klass.find(id)
    Report.create!(user: current_user, reportable: obj, reason: reason)
    redirect_to root_path, notice: 'Thanks. We will review this shortly.'
  end
end

