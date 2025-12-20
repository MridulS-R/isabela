class Admin::ReportsController < ApplicationController
  before_action :require_login
  before_action :require_admin!
  before_action :set_report, only: [:show, :update, :hide_post, :delete_post, :ban_user, :resolve, :reject]

  def index
    @reports = Report.includes(:user, :reportable).order(created_at: :desc).limit(200)
  end

  def show; end

  def update
    if @report.update(status: params[:status])
      redirect_to admin_report_path(@report), notice: 'Updated.'
    else
      render :show, status: :unprocessable_entity
    end
  end

  def hide_post
    if @report.reportable.is_a?(Post)
      @report.reportable.update!(hidden: true)
      @report.update!(status: :resolved, notes: append_note('Post hidden'))
      redirect_to admin_report_path(@report), notice: 'Post hidden.'
    else
      redirect_to admin_report_path(@report), alert: 'Not a post.'
    end
  end

  def delete_post
    if @report.reportable.is_a?(Post)
      @report.reportable.destroy
      @report.update!(status: :resolved, notes: append_note('Post deleted'))
      redirect_to admin_report_path(@report), notice: 'Post deleted.'
    else
      redirect_to admin_report_path(@report), alert: 'Not a post.'
    end
  end

  def ban_user
    target = case @report.reportable
             when User then @report.reportable
             when Post then @report.reportable.user
             when Comment then @report.reportable.user
             end
    if target
      target.update!(banned: true)
      @report.update!(status: :resolved, notes: append_note("User #{target.id} banned"))
      redirect_to admin_report_path(@report), notice: 'User banned.'
    else
      redirect_to admin_report_path(@report), alert: 'Target not found.'
    end
  end

  def resolve
    @report.update!(status: :resolved)
    redirect_to admin_report_path(@report), notice: 'Resolved.'
  end

  def reject
    @report.update!(status: :rejected)
    redirect_to admin_report_path(@report), notice: 'Rejected.'
  end

  private
  def set_report
    @report = Report.find(params[:id])
  end

  def append_note(line)
    [@report.notes.to_s, line].reject(&:blank?).join("\n")
  end
end

