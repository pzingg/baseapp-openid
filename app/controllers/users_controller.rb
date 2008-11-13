class UsersController < ApplicationController
  before_filter :require_no_user, :only => [:new, :create]
  before_filter :require_user, :only => [:index, :show, :edit, :update, :destroy,
    :edit_password, :update_password, :edit_email, :update_email]
  require_role "admin", :for => [:index, :destroy]
  
  # GET /users
  # GET /users.xml
  def index
    @users = User.find(:all)

    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @users }
    end
  end

  # GET /users/1
  # GET /users/1.xml
  def show
    # @user = User.find(params[:id])
    @user = current_user
    
    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @user }
    end
  end

  # GET /users/new
  # GET /users/new.xml
  def new
    # Advanced Rails Recipes, Chapter 13
    @user = User.new
    @user.build_profile
    @user.identities.build

    respond_to do |format|
      format.html # new.html.erb
      format.xml  { render :xml => @user }
    end
  end

  # GET /users/1/edit
  def edit
    # @user = User.find(params[:id])
    @user = current_user
    @user.build_profile unless @user.profile
    @user.identities.build
  end

  # POST /users
  # POST /users.xml
  def create
    @user = User.new(params[:user])
    
    respond_to do |format|
      if @user.valid?
        if @user.has_login?
          @user.register! # will save
        else
          @user.register_openid! # will save
        end
        flash[:notice] = "Account registered!"
        format.html do 
          flash[:notice] = "Thanks for signing up!"
          logger.info "signed up with #{@user.has_login? ? 'login' : 'OpenID'}"
          logger.info "stored url = #{session[:return_to]}"
          if @user.has_login?
            flash[:notice] << " We're sending you an email with your activation code."
            logger.info "back or default_url..."
            redirect_to default_url
          else
            flash[:notice] << " You can now login with your OpenID."
            logger.info "back or account_url..."
            redirect_back_or_default account_url
          end
        end
        format.xml  { render :xml => @user, :status => :created, :location => @user }
      else
        format.html do
          flash[:error] = "Sorry, there was an error creating your account."
          render :action => "new"
        end
        format.xml  { render :xml => @user.errors, :status => :unprocessable_entity }
      end
    end
  end

  # PUT /users/1
  # PUT /users/1.xml
  def update
    # @user = User.find(params[:id])
    @user = current_user # makes our views "cleaner" and more consistent
    params[:user][:existing_identity_attrs] ||= {} 
    
    respond_to do |format|
      if @user.update_attributes(params[:user])
        flash[:notice] = "Account updated!"
        format.html { redirect_to account_url }
        format.xml  { head :ok }
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @user.errors, :status => :unprocessable_entity }
      end
    end
  end

  # DELETE /users/1
  # DELETE /users/1.xml
  def destroy
    # destroy not implemented - only admins may "purge" or "delete" users
    raise "method not implemented"
  end
  
  def troubleshooting
    # Render troubleshooting.html.erb
    # render :layout => 'login'
  end

  def clueless
    # These users are beyond our automated help...
    # render :layout => 'login'
  end

  def forgot_login    
    if request.put?
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
      else
        UserMailer.deliver_forgot_login(@user) 
      end
    else
      # Render forgot_login.html.erb
    end
    
    # render :layout => 'login'
  end

  def forgot_password    
    if request.put?
      @user = User.find_by_login_or_email(params[:email_or_login])

      if @user.nil?
        flash.now[:error] = 'No account was found by that login or email address.'
      else
        if !@user.has_login?
          flash[:notice] = "You cannot reset your password here. You are using OpenID!"
          redirect_to :back
        else
          @user.forgot_password if @user.active?
        end
      end
    else
      # Render forgot_password.html.erb
    end
    
    # render :layout => 'login'
  end
  
  def reset_password    
    begin
      @user = User.find_by_password_reset_code(params[:password_reset_code])
    rescue
      @user = nil
    end
    
    unless @user.nil? || !@user.active?
      @user.reset_password!
    end
    
    # render :layout => 'login'
  end

  def activate
    logout!
    user = User.find_by_activation_code(params[:activation_code]) unless params[:activation_code].blank?
    case
    when (!params[:activation_code].blank?) && user && !user.active?
      user.activate!
      flash[:notice] = "Signup complete! Please sign in to continue."
      redirect_to login_url
    when params[:activation_code].blank?
      flash[:error] = "The activation code was missing.  Please follow the URL from your email."
      redirect_back_or_default default_url
    else 
      flash[:error]  = "We couldn't find a user with that activation code -- check your email? Or maybe you've already activated -- try signing in."
      redirect_back_or_default default_url
    end
  end
  
  def edit_password
    # @user = User.find(params[:id])
    @user = current_user
    if !@user.has_login?
      flash[:notice] = "You cannot update your password. You are using OpenID!"
      redirect_to :back
    end
    
    # render edit_password.html.erb
  end
  
  def update_password    
    # @user = User.find(params[:id])
    @user = current_user
    if !@user.has_login?
      flash[:notice] = "You cannot update your password. You are using OpenID!"
      redirect_to :back
    end
    
    if current_user == @user
      current_password, new_password, new_password_confirmation = params[:current_password], params[:new_password], params[:new_password_confirmation]
      
      if User.encrypt(current_password, @user.salt) == @user.crypted_password
        if new_password == new_password_confirmation
          if new_password.blank? || new_password_confirmation.blank?
            flash[:error] = "You cannot set a blank password."
            redirect_to edit_password_user_url(@user)
          else
            @user.password = new_password
            @user.password_confirmation = new_password_confirmation
            @user.save
            flash[:notice] = "Your password has been updated."
            redirect_to profile_url(@user)
          end
        else
          flash[:error] = "Your new password and it's confirmation don't match."
          redirect_to edit_password_user_url(@user)
        end
      else
        flash[:error] = "Your current password is not correct. Your password has not been updated."
        redirect_to edit_password_user_url(@user)
      end
    else
      flash[:error] = "You cannot update another user's password!"
      redirect_to edit_password_user_url(@user)
    end
  end
  
  def edit_email
    # @user = User.find(params[:id])
    @user = current_user
    if !@user.has_login?
      flash[:notice] = "You cannot update your email address. You are using OpenID!"
      redirect_to :back
    end
    
    # render edit_email.html.erb
  end
  
  def update_email
    # @user = User.find(params[:id])
    @user = current_user
    if !@user.has_login?
      flash[:notice] = "You cannot update your email address. You are using OpenID!"
      redirect_to :back
    end
    
    if current_user == @user
      if @user.update_attributes(:email => params[:email])
        flash[:notice] = "Your email address has been updated."
        redirect_to profile_url(@user)
      else
        flash[:error] = "Your email address could not be updated."
        redirect_to edit_email_user_url(@user)
      end
    else
      flash[:error] = "You cannot update another user's email address!"
      redirect_to edit_email_user_url(@user)
    end
  end
  
  protected

  def find_user
    @user = User.find(params[:id])
  end
  
  
end
