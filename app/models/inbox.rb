class Inbox < ActionMailer::Base
  
  # mail is sent here by cron_fetcher.rb script run from crontab
  def receive(mail)
    if configatron.admin_emails.include?(mail.from.address.downcase)
      receive_admin_mail(mail)
    else
      receive_user_mail(mail)
    end
  end
  
  protected
  
  def receive_admin_mail(mail)
    subj = mail.subject
    m = subj.match(/^passwords?\s+(\S+)/i)
    if m
      send_passwords(mail, m[1])
    else
      processing_error(mail, "command not understood: #{subj}")
    end
  end
  
  def receive_user_mail(mail)
    send_passwords(mail, mail.from.address)
  end

  def send_passwords(mail, user_email)
    user = User.find_by_email(user_email)
    if user
      UserMailer.deliver_password_reminder(user)
    else
      processing_error(mail, "user not found: #{user_email}")
    end
  end
  
  def processing_error(mail, error_msg)
    # send a message to admin?
    # write something to log file?
    raise error_msg
  end
  
end
