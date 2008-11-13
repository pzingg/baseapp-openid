class CreateProfiles < ActiveRecord::Migration
  def self.up
    create_table :profiles do |t|
      t.integer :user_id
      t.string  :first_name
      t.string  :last_name
      t.string  :sms_phone_number
      t.string  :twitter_username
      t.string  :meebo_id
      t.integer :student_number
      t.integer :home_id
      t.integer :teacher_number
      t.string  :access_type

      t.timestamps
    end
  end

  def self.down
    drop_table :profiles
  end
end
