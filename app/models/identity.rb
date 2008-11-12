# == Schema Information
# Schema version: 20081111233821
#
# Table name: identities
#
#  id         :integer(4)      not null, primary key
#  url        :string(255)
#  user_id    :integer(4)
#  created_at :datetime
#  updated_at :datetime
#

class Identity < ActiveRecord::Base
  belongs_to :user
  
  validates_uniqueness_of :url
  validate :normalize_url
  
  def normalize_url
    self.url = OpenIdAuthentication.normalize_url(url)
  rescue
    errors.add_to_base("Invalid OpenID URL")
  end
end
