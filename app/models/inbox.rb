class Inbox < ActionMailer::Base
  
  # mail is sent here by cron_fetcher.rb script run from crontab
  def receive(mail)
    from = (mail.from || []).first
    return processing_error(mail, "no from address") if from.blank?
    if configatron.admin_emails.include?(from.downcase)
      receive_admin_mail(mail, from)
    else
      receive_user_mail(mail, from)
    end
  end
  
  protected
  
  def receive_admin_mail(mail, from)
    subj = mail.subject
    puts "receive_admin_mail: #{subj}"
    m = subj.match(/^passwords?\s+(\S+)/i)
    if m
      send_passwords(mail, m[1], from)
    else
      processing_error(mail, "command not understood: #{subj}")
    end
  end
  
  def receive_user_mail(mail, from)
    puts "receive_user_mail: #{from}"
    send_passwords(mail, from)
  end

  def send_passwords(mail, user_email, admin_email=nil)
    user = User.find_by_email(user_email)
    if user
      begin
        puts "deliver_password_reminder #{user.email}, #{admin_email}"
        puts "method        #{ActionMailer::Base::delivery_method.inspect}"
        puts "exceptions    #{ActionMailer::Base::raise_delivery_errors.inspect}"
        puts "perform       #{ActionMailer::Base::perform_deliveries.inspect}"
        puts "smtp_settings #{ActionMailer::Base::smtp_settings.inspect}"
        UserMailer.deliver_password_reminder(user, admin_email)
      rescue
        puts "user mailer said #{$!}"
        raise
      end
    else
      processing_error(mail, "user not found: #{user_email}")
    end
  end
  
  def processing_error(mail, error_msg)
    # send a message to admin?
    # write something to log file?
    puts "mail processing error: #{error_msg}"
    raise error_msg
  end
  
end
