class UserMailer < ActionMailer::Base
  def signup_notification(user, password)
    setup_email(user)
    @subject    += 'Please activate your new account'
    @body[:url]  = "#{configatron.site_url}/activate/#{user.activation_code}"
    @body[:password] = password
  end
  
  def reset_password(user, password)
    setup_email(user)
    @subject += "Your password has been reset"
    @body[:url]  = "#{configatron.site_url}/login"
    @body[:password] = password
  end
  
  def forgot_password(user)
    setup_email(user)
    @subject += "Forgotten password instructions"
    @body[:url]  = "#{configatron.site_url}/reset_password/#{user.password_reset_code}"
  end
  
  def forgot_login(user)
    setup_email(user)
    @subject += "Forgotten account login"
    @body[:url]  = "#{configatron.site_url}/login"
  end
  
  def activation(user)
    setup_email(user)
    @subject    += 'Your account has been activated!'
    @body[:url]  = "#{configatron.site_url}/"
  end
  
  def admin_notification(user, subject)
    @recipients  = configatron.support_email
    @from        = "#{configatron.support_name} <#{configatron.support_email}>"
    @subject     = "[#{configatron.site_name}] #{subject}"
    @sent_on     = Time.now
    @body[:user] = user
    @body[:url]  = edit_admin_user_url(user)
    
    # Get Settings
    [:site_name, :company_name, :support_email, :support_name].each do |id|
      @body[id] = configatron.send(id)
    end
  end
  
  protected
    def setup_email(user)
      @recipients  = "#{user.email}"
      @from        = "#{configatron.support_name} <#{configatron.support_email}>"
      @subject     = "[#{configatron.site_name}] "
      @sent_on     = Time.now
      @body[:user] = user
      
      # Get Settings
      [:site_name, :company_name, :support_email, :support_name].each do |id|
        @body[id] = configatron.send(id)
      end
    end
end
