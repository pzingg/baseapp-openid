class UsersController < ApplicationController
  before_filter :require_no_user, :only => [:new, :create]
  before_filter :require_user, :only => [:show, :edit, :update]
  
  # GET /users
  # GET /users.xml
  def index
    # index not implemented - only admins may list users
    raise "This action is not implemented"
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
    unless configatron.user_can_change_login
      @user_login_is_readonly = true
    end
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
    unless configatron.user_can_change_login
      params[:user].delete(:login)
      @user_login_is_readonly = true
    end
    
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
    raise "This action is not implemented"
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

  protected

  def find_user
    @user = User.find(params[:id])
  end
  
  
end
