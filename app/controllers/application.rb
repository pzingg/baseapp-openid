# Filters added to this controller apply to all controllers in the application.
# Likewise, all the methods added will be available for all controllers.

class ApplicationController < ActionController::Base
  # AuthenticatedSystem must be included for RoleRequirement, and is provided by installing acts_as_authenticates and running 'script/generate authenticated account user'.
  include AuthenticatedSystem
  # You can move this into a different controller, if you wish.  This module gives you the require_role helpers, and others.
  include RoleRequirementSystem

  helper :all # include all helpers, all the time

  # See ActionController::RequestForgeryProtection for details
  # Uncomment the :secret if you're not using the cookie session store
  protect_from_forgery # :secret => '03ffdfb0eb509a3386057b91cdd8983a'
  
  # See ActionController::Base for details 
  # Uncomment this to filter the contents of submitted sensitive data parameters
  # from your application log (in this case, all fields with names like "password"). 
  # filter_parameter_logging :password

  # authlogic user sessions
  helper_method :user_session, :current_user, :logged_in
  before_filter :load_user
  
  def access_denied
    flash[:error] = "No entry"
    redirect_to default_url
  end
    
  private

  def load_user
    @user_session = UserSession.find
    @current_user = @user_session && @user_session.record
  end
  
  def logged_in?
    !current_user.nil?
  end

  def user_session
    @user_session
  end

  def current_user
    @current_user
  end
  
  def logout!
    @current_user = nil
    if @user_session
      us = @user_session
      @user_session = nil
      us.destroy
    end
  end 

  def require_user
    unless @current_user
      store_location
      flash[:notice] = "You must be logged in to access this page"
      redirect_to login_url
      return false
    end
  end

  def require_no_user
    if @current_user
      store_location
      flash[:notice] = "You must be logged out to access this page"
      redirect_to account_url
      return false
    end
  end

  def store_location
    session[:return_to] = request.request_uri
  end

  def redirect_back_or_default(default)
    redirect_to(session[:return_to] || default)
    session[:return_to] = nil
  end
end
