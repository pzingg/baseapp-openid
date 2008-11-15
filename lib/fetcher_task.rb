#!/usr/bin/env ruby

# add a crontab line to run this script
# ACCOUNTMGR_ROOT=/users/me/rails/accountmgr
# ACCOUNTMGR_LOGDIR=/var/log
# 32 * * * * cd "$ACCOUNTMGR_ROOT"; RAILS_ENV=development /usr/bin/env ruby \
# ./script/runner 'FetcherTask.fetch' 2>&1 >> "$ACCOUNTMGR_LOGDIR/cron_fetcher.log"

class FetcherTask
  def self.fetch
    begin 
      Lockfile.new('cron_mail_fetcher.lock', :retries => 0) do 
        config = YAML.load_file("#{RAILS_ROOT}/config/mail.yml") 
        opts = config[RAILS_ENV]['incoming'].to_options 
        puts "Running Fetcher in #{RAILS_ENV} mode" 
        fetcher = Fetcher.create({ :receiver => Inbox }.merge(opts)) 
        fetcher.fetch 
        puts "Finished running Fetcher in #{RAILS_ENV} mode" 
      end 
    rescue Lockfile::MaxTriesLockError => e 
      puts "Another Fetcher instance is already running. Exiting." 
    end 
  end
end