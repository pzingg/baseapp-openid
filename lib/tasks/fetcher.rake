namespace :fetcher do
  desc "fetch support mail"
  task :fetch => :environment do
    FetcherTask.fetch
  end
end