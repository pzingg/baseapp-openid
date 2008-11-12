class UserSessionsController < ApplicationController
  before_filter :require_no_user, :only => [:new, :create]
  before_filter :require_user, :only => :destroy
  
  def new
    @user_session = UserSession.new
  end

  def create
    # The openid login form has to have an input with 
    # name="openid_url" (per openid spec and per open_id_authentication plugin)
    # id="openid_identifier" (per idselector.com)
    # using_open_id? and authenticate_with_open_id use params[:openid_url] and
    # params[:open_id_complete] to deal with the redirecting to the openid
    # provider and coming back to us
    if using_open_id?
      authenticate_with_open_id do |result, identity_url|
        if result.successful?
          user = User.find_by_open_id(identity_url)
          if !user.nil?
            @user_session = UserSession.new(user) if user
          else
            flash[:error] = "Sorry, no user by that identity URL exists (#{identity_url})."
            redirect_to new_user_session_path
          end
        else
          flash[:error] = "Open ID authentication failed."
          redirect_to new_user_session_path
        end
      end
      return unless @user_session
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
