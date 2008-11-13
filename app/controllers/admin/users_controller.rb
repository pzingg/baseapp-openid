class Admin::UsersController < ApplicationController
  require_role 'admin'
  # layout 'admin'

  # GET /admin_users
  # GET /admin_users.xml
  def index
    @users = User.paginate :all, paginate_options
    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @users }
    end
  end

  # GET /admin_users/1
  # GET /admin_users/1.xml
  def show
    @user = User.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @user }
    end
  end

  # GET /admin_users/new
  # GET /admin_users/new.xml
  def new
    @user = User.new
    @user.build_profile unless @user.profile
    # @user.identities.build # don't add OpenID in admin interface

    respond_to do |format|
      format.html # new.html.erb
      format.xml  { render :xml => @user }
    end
  end
  
  # GET /admin_users/1/edit
  def edit
    @user = User.find(params[:id])
    @user.build_profile unless @user.profile
    # @user.identities.build # don't add OpenID in admin interface
  end

  # POST /admin_users
  # POST /admin_users.xml
  def create
    @user = User.new(params[:user])

    respond_to do |format|
      if @user.save
        flash[:notice] = "Account was successfully created."
        format.html { redirect_to(admin_user_url(@user)) }
        format.xml  { render :xml => @user, :status => :created, :location => @user }
      else
        format.html { render :action => "new" }
        format.xml  { render :xml => @user.errors, :status => :unprocessable_entity }
      end
    end
  end
  
  
  # PUT /admin_users/1
  # PUT /admin_users/1.xml
  def update
    @user = User.find(params[:id])
    params[:user][:existing_identity_attrs] ||= {} 
    
    respond_to do |format|
      if @user.update_attributes(params[:user])
        flash[:notice] = "Account updated!"
        format.html { redirect_to admin_users_url }
        format.xml  { head :ok }
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @user.errors, :status => :unprocessable_entity }
      end
    end
  end
  
  # DELETE /admin_users/1
  # DELETE /admin_users/1.xml
  def destroy
    @user = User.find(params[:id])
    @user.delete!

    redirect_to admin_user_url(@user)
  end
  
  def reset_password
    @user = User.find(params[:id])
    @user.reset_password!
    
    flash[:notice] = "A new password has been sent to the user by email."
    redirect_to admin_user_url(@user)
  end
  
  def unapproved
    @users = User.paginate :all, paginate_options('unapproved')
    render :action => 'index'
  end
  
  def pending
    @users = User.paginate :all, paginate_options('pending')
    render :action => 'index'
  end
  
  def suspended
    @users = User.paginate :all, paginate_options('suspended')
    render :action => 'index'
  end
  
  def active
    @users = User.paginate :all, paginate_options('active')
    render :action => 'index'
  end
  
  def deleted
    @users = User.paginate :all, paginate_options('deleted')
    render :action => 'index'
  end
  
  def approve
    @user = User.find(params[:id])
    @user.approve!
    redirect_to admin_user_url(@user)
  end
    
  def activate
    @user = User.find(params[:id])
    @user.activate!
    redirect_to admin_user_url(@user)
  end
  
  def suspend
    @user = User.find(params[:id])
    @user.suspend! 
    redirect_to admin_user_url(@user)
  end

  def unsuspend
    @user = User.find(params[:id])
    @user.unsuspend! 
    redirect_to admin_user_url(@user)
  end

  def purge
    @user = User.find(params[:id])
    @user.destroy
    redirect_to admin_users_url
  end
  
  protected
  
  def paginate_options(state=nil)
    { :include => :profile, :conditions => state_conditions(state), :order => ['profiles.last_name, profiles.first_name, login'], :page => params[:page] }
  end
  
  def state_conditions(state=nil)
    params[:initial].blank? ?
      (state.blank? ? nil : ['state=?', state]) :
      (state.blank? ? ['profiles.last_name LIKE ?', "#{params[:initial]}%"] :
        ['state=? AND profiles.last_name LIKE ?', state, "#{params[:initial]}%"])
  end
end
