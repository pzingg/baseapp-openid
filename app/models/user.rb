# == Schema Information
# Schema version: 20081111194114
#
# Table name: users
#
#  id               :integer(4)      not null, primary key
#  login            :string(255)
#  crypted_password :string(255)
#  password_salt    :string(255)
#  remember_token   :string(255)
#  login_count      :integer(4)
#  last_request_at  :datetime
#  last_login_at    :datetime
#  current_login_at :datetime
#  last_login_ip    :string(255)
#  current_login_ip :string(255)
#  created_at       :datetime
#  updated_at       :datetime
#

class User < ActiveRecord::Base
  acts_as_authentic
  
end
