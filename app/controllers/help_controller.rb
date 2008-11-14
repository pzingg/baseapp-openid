class HelpController < ApplicationController

  def troubleshooting
    # Render troubleshooting.html.erb
    # render :layout => 'login'
  end

  def clueless
    # These users are beyond our automated help...
    # render :layout => 'login'
  end

  def forgot_login    
    if request.post?
      begin
        @user = User.find_by_email(params[:email], :conditions => ['NOT state = ?', 'deleted'])
        
        if !@user.has_login?
          flash[:notice] = "Sorry.  We cannot help you if you're using OpenID!"
          redirect_to :back
        end
      rescue
        @user = nil
      end
      
      if @user.nil?
        flash.now[:error] = 'No account was found with that email address.'
      elsif @user.active?
        UserMailer.deliver_forgot_login(@user) 
      else
        flash[:notice] = "Your account is not active. Please contact support for help."
        redirect_to :back
      end
    else
      # Render forgot_login.html.erb
    end
  end

  def forgot_password    
    if request.post?
      @user = User.find_by_login_or_email(params[:email_or_login])

      if @user.nil?
        flash.now[:error] = 'No account was found by that login or email address.'
      else
        if !@user.has_login?
          flash[:notice] = "You cannot reset your password here. You are using OpenID!"
          redirect_to :back
        elsif @user.active?
          @user.forgot_password
        else
          flash[:notice] = "Your account is not active. Please contact support for help."
          redirect_to :back
        end
      end
    else
      # Render forgot_password.html.erb
    end
  end

end