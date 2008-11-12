class UserSessionsController < ApplicationController
  before_filter :require_no_user, :only => [:new, :create]
  before_filter :require_user, :only => :destroy
  
  def new
    @user_session = UserSession.new
  end

  def create
    if params[:user_session][:login].blank?
      # open_id lookup
      unauth_user = User.find_by_open_id(params[:user_session][:identity_url])
      @user_session = UserSession.new(unauth_user)
    else
      @user_session = UserSession.new(params[:user_session])
    end
    if @user_session.save
      flash[:notice] = "Login successful!"
      redirect_back_or_default account_url
    else
      render :action => :new
    end
  end

  def destroy
    @user_session.destroy
    flash[:notice] = "Logout successful!"
    redirect_back_or_default new_user_session_url
  end
end
