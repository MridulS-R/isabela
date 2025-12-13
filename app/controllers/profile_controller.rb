class ProfileController < ApplicationController
  before_action :require_login

  def show
    @is_admin = admin_user?
  end
end

