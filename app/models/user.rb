# == Schema Information
# Schema version: 20081111233821
#
# Table name: users
#
#  id                        :integer(4)      not null, primary key
#  login                     :string(255)
#  email                     :string(255)
#  state                     :string(255)     default("passive")
#  crypted_password          :string(255)
#  password_salt             :string(255)
#  remember_token            :string(255)
#  activation_code           :string(40)
#  password_reset_code       :string(40)
#  login_count               :integer(4)
#  last_request_at           :datetime
#  last_login_at             :datetime
#  current_login_at          :datetime
#  activated_at              :datetime
#  deleted_at                :datetime
#  remember_token_expires_at :datetime
#  last_login_ip             :string(255)
#  current_login_ip          :string(255)
#  im                        :string(255)
#  twitter                   :string(255)
#  cell_phone                :string(255)
#  created_at                :datetime
#  updated_at                :datetime
#

class User < ActiveRecord::Base  
  include AASM
  
  # Relations
  has_and_belongs_to_many :roles
  has_many :identities, :dependent => :destroy
  has_one :profile, :dependent => :destroy
  delegate :last_name, :first_name, :to => :profile

  after_save :check_activation
  validates_associated :identities, :message => 'could not be validated'
  
  # authlogic will validate the login field, but we will validate the email field
  # This is purposefully imperfect -- it's just a check for bogus input. See
  # http://www.regular-expressions.info/email.html
  RE_EMAIL_NAME   = '[\w\.%\+\-]+'                          # what you actually see in practice
  #RE_EMAIL_NAME   = '0-9A-Z!#\$%\&\'\*\+_/=\?^\-`\{|\}~\.' # technically allowed by RFC-2822
  RE_DOMAIN_HEAD  = '(?:[A-Z0-9\-]+\.)+'
  RE_DOMAIN_TLD   = '(?:[A-Z]{2}|com|org|net|edu|gov|mil|biz|info|mobi|name|aero|jobs|museum)'
  RE_EMAIL_OK     = /\A#{RE_EMAIL_NAME}@#{RE_DOMAIN_HEAD}#{RE_DOMAIN_TLD}\z/i
  MSG_EMAIL_BAD   = "should look like an email address."
  
  validates_presence_of :email, :if => :has_login?
  validates_length_of :email, :within => 6..100, :if => :has_login?
  validates_uniqueness_of :email, :case_sensitive => false, :if => :has_login?
  validates_format_of :email, :with => RE_EMAIL_OK, :message => MSG_EMAIL_BAD, :if => :has_login?

  # State Machine
  aasm_column :state
  aasm_initial_state :initial => :pending
  aasm_state :passive
  aasm_state :unapproved, :enter => :check_auto_approval
  aasm_state :pending,    :enter => :notify_or_activate_user
  aasm_state :active,     :enter => :do_activate
  aasm_state :suspended
  aasm_state :deleted,    :enter => :do_delete

  aasm_event :register do
    transitions :from => :passive, :to => :unapproved, :guard => Proc.new {|u| !(u.crypted_password.blank? && u.password.blank?) }
  end
  
  aasm_event :register_openid do
    transitions :from => :passive, :to => :unapproved, :guard => Proc.new {|u| !u.has_login? }
  end
  
  aasm_event :approve do
    transitions :from => :unapproved, :to => :pending
  end
  
  aasm_event :activate do
    transitions :from => [:unapproved, :pending], :to => :active
  end
  
  aasm_event :suspend do
    transitions :from => [:passive, :unapproved, :pending, :active], :to => :suspended
  end
  
  aasm_event :delete do
    transitions :from => [:passive, :unapproved, :pending, :active, :suspended], :to => :deleted
  end

  aasm_event :unsuspend do
    transitions :from => :suspended, :to => :active,  :guard => Proc.new {|u| !u.activated_at.blank? }
    transitions :from => :suspended, :to => :pending, :guard => Proc.new {|u| !u.activation_code.blank? }
    transitions :from => :suspended, :to => :passive
  end
  
  acts_as_authentic :crypto_provider => PasswordEncryption
  # authlogic functions we can call
  #
  #   User.crypto_provider        The class that you set in your :crypto_provider option
  #   User.forget_all!            Finds all records, loops through them, and calls forget! on each record. This is paginated to save on memory.
  #   User.unique_token           returns unique token
  #
  #   User.logged_in              Find all users who are logged in, based on your :logged_in_timeout option.
  #   User.logged_out             Same as above, but logged out.
  #
  #   user.password=              Method name based on the :password_field option. This is used to set the password. Pass the *raw* password to this.
  #   user.confirm_password=      Confirms the password, needed to change the password.
  #   user.valid_password?(pass)  Determines if the password passed is valid. The password could be encrypted or raw.
  #   user.reset_password!        Basically resets the password to a random password using only letters and numbers.
  #   user.logged_in?             Based on the :logged_in_timeout option. Tells you if the user is logged in or not.
  #   user.forget!                Changes their remember token, making their cookie and session invalid. A way to log the user out withouth changing their password.
  
  # has_role? simply needs to return true or false whether a user has a role or not.  
  # It may be a good idea to have "admin" roles return true always
  def has_role?(role_in_question)
    @_list ||= self.roles.collect(&:name)
    @_list.include?("admin") ? true :
      (role_in_question.blank? ? false : @_list.include?(role_in_question.to_s))
  end
  
  def admin?
    has_role?(nil)
  end

  def has_login?
    !(self.login.blank? || self.crypted_password.blank?)
  end
  
  def has_open_id?
    !self.identities.blank?
  end
  
  def has_email?
    !self.email.blank?
  end
  
  def last_first
    sep = (last_name.blank? || first_name.blank?) ? '' : ', '
    "#{last_name}#{sep}#{first_name}"
  end
  
  def last_login_s
    last_login_at.nil? ? 'Never' : last_login_at.to_s(:short)
  end
  
  def password_with_case=(pass)
    return if pass.blank?
    self.tried_to_set_password = true
    pass = pass.downcase if configatron.downcase_passwords
    @password_with_case = pass
    self.remember_token = self.class.unique_token
    self.password_salt = self.class.unique_token
    self.crypted_password = crypto_provider.encrypt(@password_with_case + self.password_salt)
  end
  
  # Returns true if the user has just been activated.
  def recently_activated?
    @activated
  end
  
  # def password_required?
  #   new_record? ? has_login? && (crypted_password.blank? || !password.blank?) : !password.blank?
  # end
  
  # ovveride authlogic for case sensitivity
  def password=(pass)
    return if pass.blank?
    self.tried_to_set_password = true
    pass = pass.downcase if configatron.downcase_passwords
    @password = pass
    self.remember_token = self.class.unique_token
    self.password_salt = self.class.unique_token
    self.crypted_password = crypto_provider.encrypt(@password + password_salt)
  end
  
  # override authlogic for case sensitivity
  def valid_password?(attempted_password)
    attempted_password = attempted_password.downcase if configatron.downcase_passwords
    return false if attempted_password.blank? || crypted_password.blank? || password_salt.blank?
    attempted_password == crypted_password ||
      (crypto_provider.respond_to?(:decrypt) && crypto_provider.decrypt(crypted_password) == attempted_password + password_salt) ||
      (!crypto_provider.respond_to?(:decrypt) && crypto_provider.encrypt(attempted_password + password_salt) == crypted_password)
  end

  # Creates a new password for the user, and notifies him with an email
  # override authlogic to use pronouncable password, and to email the user
  def reset_password!
    newpass = self.class.random_pronouncable_password(3)
    self.password = newpass
    self.confirm_password = newpass
    self.password_reset_code = nil
    save_without_session_maintenance(false)

    if self.has_email?
      UserMailer.deliver_reset_password(self, decrypted_password)
    else
      UserMailer.deliver_admin_notification(self, 'Reset password')
    end
  end

  def check_activation
    if self.recently_activated? && self.has_login?
      if self.has_email?
        UserMailer.deliver_activation(self)
      else
        UserMailer.deliver_admin_notification(self, 'Activation failure')
      end
    end
  end

  def decrypted_password
    return nil if self.crypted_password.blank? || self.password_salt.blank?
    clearpass = User.crypto_provider.decrypt(self.crypted_password)
    i_salt = clearpass.index(self.password_salt)
    i_salt.nil? ? nil : clearpass[0, i_salt]
  end

  def forgot_password
    self.make_password_reset_code
    save
    
    if self.has_email?
      UserMailer.deliver_forgot_password(self) 
    else
      UserMailer.deliver_admin_notification(self, 'Forgot password')
    end
  end

  # Advanced Rails Recipes, Chapter 13
  after_update :save_identities
  
  def profile_attrs=(profile_attrs)
    self.build_profile unless self.profile
    self.profile.attributes = profile_attrs
  end

  def new_identity_attrs=(identity_attrs) 
    identity_attrs.each do |attrs|
      if !attrs[:url].blank? && !attrs[:url].match(/^Click/)
        self.identities.build(attrs)
      end
    end
  end 

  def existing_identity_attrs=(identity_attrs)
    identities.reject(&:new_record?).each do |identity| 
      attributes = identity_attrs[identity.id.to_s] 
      if attributes
        identity.attributes = attributes 
      else 
        identities.delete(identity) 
      end 
    end 
  end
   
  def save_identities 
    identities.each do |identity|
      identity.save(false)
    end
  end 
  
  class << self
    # use authlogic's unique_token generator
    alias_method :make_token, :unique_token
    
    def find_by_login_or_email(login_or_email)
      find(:first, :conditions => ['login = ? OR email = ?', login_or_email, login_or_email])
    rescue
      nil
    end
    
    def find_by_open_id(identity_url)
      ident = Identity.find_by_url(OpenIdAuthentication.normalize_url(identity_url))
      ident.nil? ? nil : ident.user
    end

    def random_pronouncable_password(size = 6)
      # skip 0, 1, o, i, L, 5, s because they are so confusing
      consonants = %w(b c d f g h j k m n p qu r t v w x z ch cr fr nd ng nk nt ph pr rd th tr 2 3 4 6 7 8 9)
      vocals = %w(a e u y)

      alternate=true
      password=''

      (size * 2).times do
        # get a random vocal or consonant
        chunk = (alternate ? consonants[rand * consonants.size] : vocals[rand * vocals.size])
        chunk = chunk.upcase if !configatron.downcase_passwords && (rand > 0.5)
        password << chunk
        alternate = !alternate
      end
      password
    end
  end

  # User#active? is defined by aasm...
  
  def approved?     # authlogic: Has the record been approved?
    ['pending', 'active'].include? self.state
  end
  
  def confirmed?    # authlogic: Has the record been confirmed?
    approved?
  end

  protected

  def make_activation_code
    self.deleted_at = nil
    self.activation_code = self.class.make_token[40, 40]
  end

  def make_password_reset_code
    self.password_reset_code = self.class.make_token[40, 40]
  end
  
  def check_auto_approval
    approve! if configatron.auto_approve
  end

  def notify_or_activate_user
    if self.has_login?
      self.make_activation_code
      save
      
      if self.has_email?
        UserMailer.deliver_signup_notification(self, decrypted_password)
      else
        UserMailer.deliver_admin_notification(self, 'Signup notification')
      end
    else
      activate!
    end
  end

  def do_activate
    @activated = true
    self.activated_at = Time.now.utc
    self.deleted_at = self.activation_code = nil
  end
  
  def approve_if_required
  end
  
  def do_delete
    self.deleted_at = Time.now.utc
  end

end
