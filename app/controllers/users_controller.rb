class UsersController < ApplicationController
  before_filter :require_no_user, :only => [:new, :create]
  before_filter :require_user, :only => [:index, :show, :edit, :update, :destroy]
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
    @user.identities.build
  end

  # POST /users
  # POST /users.xml
  def create
    @user = User.new(params[:user])
    @user.identities << Identity.new(params[:user][:identity]) if params[:user][:identity]
    respond_to do |format|
      if @user.valid?
        if @user.not_using_openid?
          @user.register! # will save
        else
          @user.register_openid! # will save
        end
        flash[:notice] = "Account registered!"
        format.html do 
          redirect_back_or_default account_url
          flash[:notice] = "Thanks for signing up!"
          if @user.not_using_openid?
            flash[:notice] << " We're sending you an email with your activation code."
          else
            flash[:notice] << " You can now login with your OpenID."
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
    params[:user][:existing_identity_attributes] ||= {} 
    
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
    return
    
    # @user = User.find(params[:id])
    @user = current_user
    @user.destroy

    respond_to do |format|
      format.html { redirect_to(users_url) }
      format.xml  { head :ok }
    end
  end
  
end
