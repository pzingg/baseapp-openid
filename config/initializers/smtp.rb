config = YAML.load_file("#{RAILS_ROOT}/config/mail.yml") 
opts = config[RAILS_ENV]['outgoing'].to_options

ActionMailer::Base.delivery_method = opts.delete(:delivery_method) if opts.key?(:delivery_method)
ActionMailer::Base.perform_deliveries = opts.delete(:perform_deliveries) if opts.key?(:perform_deliveries)
ActionMailer::Base.raise_delivery_errors = opts.delete(:raise_delivery_errors) if opts.key?(:raise_delivery_errors)
ActionMailer::Base.smtp_settings = opts
