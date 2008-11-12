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
  acts_as_authentic
  
  # Uncomment to suit
  RE_LOGIN_OK     = /\A\w[\w\.\-_@]+\z/                     # ASCII, strict
  # RE_LOGIN_OK   = /\A[[:alnum:]][[:alnum:]\.\-_@]+\z/     # Unicode, strict
  # RE_LOGIN_OK   = /\A[^[:cntrl:]\\<>\/&]*\z/              # Unicode, permissive
  MSG_LOGIN_BAD   = "use only letters, numbers, and .-_@ please."

  RE_NAME_OK      = /\A[^[:cntrl:]\\<>\/&]*\z/              # Unicode, permissive
  MSG_NAME_BAD    = "avoid non-printing characters and \\&gt;&lt;&amp;/ please."

  # This is purposefully imperfect -- it's just a check for bogus input. See
  # http://www.regular-expressions.info/email.html
  RE_EMAIL_NAME   = '[\w\.%\+\-]+'                          # what you actually see in practice
  #RE_EMAIL_NAME   = '0-9A-Z!#\$%\&\'\*\+_/=\?^\-`\{|\}~\.' # technically allowed by RFC-2822
  RE_DOMAIN_HEAD  = '(?:[A-Z0-9\-]+\.)+'
  RE_DOMAIN_TLD   = '(?:[A-Z]{2}|com|org|net|edu|gov|mil|biz|info|mobi|name|aero|jobs|museum)'
  RE_EMAIL_OK     = /\A#{RE_EMAIL_NAME}@#{RE_DOMAIN_HEAD}#{RE_DOMAIN_TLD}\z/i
  MSG_EMAIL_BAD   = "should look like an email address."

  
  
  # Relations
  has_and_belongs_to_many :roles
  has_many :identities

  # Validations
  validates_presence_of :login, :if => :not_using_openid?
  validates_length_of :login, :within => 3..40, :if => :not_using_openid?
  validates_uniqueness_of :login, :case_sensitive => false, :if => :not_using_openid?
  validates_format_of :login, :with => RE_LOGIN_OK, :message => MSG_LOGIN_BAD, :if => :not_using_openid?
  validates_presence_of :email, :if => :not_using_openid?
  validates_length_of :email, :within => 6..100, :if => :not_using_openid?
  validates_uniqueness_of :email, :case_sensitive => false, :if => :not_using_openid?
  validates_format_of :email, :with => RE_EMAIL_OK, :message => MSG_EMAIL_BAD, :if => :not_using_openid?

  # State Machine
  aasm_column :state
  aasm_initial_state :initial => :pending
  aasm_state :passive
  aasm_state :pending, :enter => :make_activation_code
  aasm_state :active,  :enter => :do_activate
  aasm_state :suspended
  aasm_state :deleted, :enter => :do_delete

  aasm_event :register do
    transitions :from => :passive, :to => :pending, :guard => Proc.new {|u| !(u.crypted_password.blank? && u.password.blank?) }
  end
  
  aasm_event :register_openid do
    transitions :from => :passive, :to => :active, :guard => Proc.new {|u| !u.not_using_openid? }
  end
  
  aasm_event :activate do
    transitions :from => :pending, :to => :active 
  end
  
  aasm_event :suspend do
    transitions :from => [:passive, :pending, :active], :to => :suspended
  end
  
  aasm_event :delete do
    transitions :from => [:passive, :pending, :active, :suspended], :to => :deleted
  end

  aasm_event :unsuspend do
    transitions :from => :suspended, :to => :active,  :guard => Proc.new {|u| !u.activated_at.blank? }
    transitions :from => :suspended, :to => :pending, :guard => Proc.new {|u| !u.activation_code.blank? }
    transitions :from => :suspended, :to => :passive
  end
  
  # has_role? simply needs to return true or false whether a user has a role or not.  
  # It may be a good idea to have "admin" roles return true always
  def has_role?(role_in_question)
    @_list ||= self.roles.collect(&:name)
    return true if @_list.include?("admin")
    (@_list.include?(role_in_question.to_s) )
  end

	def not_using_openid?
		self.identities.blank?
	end
  
  # Returns true if the user has just been activated.
  def recently_activated?
    @activated
  end
  
  def password_required?
    new_record? ? not_using_openid? && (crypted_password.blank? || !password.blank?) : !password.blank?
  end

  # Creates a new password for the user, and notifies him with an email
  def reset_password!
    password = self.class.random_pronouncable_password(3)
    self.password = password
    self.password_confirmation = password
    self.password_reset_code = nil
    save

    # UserMailer.deliver_reset_password(self)
  end

  def forgot_password
    self.make_password_reset_code
    save
    
    # UserMailer.deliver_forgot_password(self)
  end

  class << self
    def find_by_login_or_email(login_or_email)
      find(:first, :conditions => ['login = ? OR email = ?', login_or_email, login_or_email])
    rescue
      nil
    end

    def make_token
      unique_token # authlogic's method
    end

    def random_pronouncable_password(size = 6)
      consonants = %w(b c d f g h j k l m n p qu r s t v w x z ch cr fr nd ng nk nt ph pr rd sh sl sp
    st th tr 0 1 2 3 4 5 6 7 8 9 0)
      vocals = %w(a e i o u y)

      alternate=true
      password=''

      (size * 2).times do
        # get a random vocal or consonant
        chunk = (alternate ? consonants[rand * consonants.size] : vocals[rand * vocals.size])
        alternate = !alternate
        # randomly swap its case & add to password
        chunk = chunk.swapcase if rand > 0.5
        password << chunk
      end
      password
    end
  end

  protected

  def make_activation_code
    self.deleted_at = nil
    self.activation_code = self.class.make_token
  end

  def make_password_reset_code
    self.password_reset_code = self.class.make_token
  end
  
  def do_delete
    self.deleted_at = Time.now.utc
  end

  def do_activate
    @activated = true
    self.activated_at = Time.now.utc
    self.deleted_at = self.activation_code = nil
  end
end
