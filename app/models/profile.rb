# == Schema Information
# Schema version: 20081113203210
#
# Table name: profiles
#
#  id               :integer(4)      not null, primary key
#  user_id          :integer(4)
#  first_name       :string(255)
#  last_name        :string(255)
#  sms_phone_number :string(255)
#  twitter_username :string(255)
#  meebo_id         :string(255)
#  student_number   :integer(4)
#  home_id          :integer(4)
#  teacher_number   :integer(4)
#  access_type      :string(255)
#  created_at       :datetime
#  updated_at       :datetime
#

class Profile < ActiveRecord::Base
  belongs_to :user
end
